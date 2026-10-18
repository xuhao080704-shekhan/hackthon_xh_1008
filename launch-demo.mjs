import {
  existsSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
  readdirSync,
  appendFileSync,
} from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { randomBytes } from 'node:crypto';
import { spawn } from 'node:child_process';
import net from 'node:net';
const here = path.dirname(fileURLToPath(import.meta.url));
const root = existsSync(path.join(here, 'app', 'server.js'))
  ? here
  : path.join(path.dirname(here), 'outputs', 'Tongpin-Windows');
// Read only the three server-side AI settings; never copy keys into the bundle.
const aiSettings = {};
const aiConfigFile = path.join(root, '.env');
if (existsSync(aiConfigFile)) {
  const contents = readFileSync(aiConfigFile, 'utf8');
  for (const name of ['AI_API_BASE_URL', 'AI_API_KEY', 'AI_MODEL']) {
    const match = contents.match(
      new RegExp('^' + name + '\\s*=\\s*(?:"([^"\\r\\n]*)"|([^#\\r\\n]*))\\s*$', 'm'),
    );
    const value = (match?.[1] ?? match?.[2] ?? '').trim();
    if (value) aiSettings[name] = value;
  }
}
Object.assign(process.env, aiSettings);
const appDir = existsSync(path.join(root, 'app', 'server.js'))
  ? path.join(root, 'app')
  : path.join(root, '.next', 'standalone');
const dataDir = process.env.DEMO_DATA_DIR
  ? path.resolve(process.env.DEMO_DATA_DIR)
  : path.join(root, '.demo');
mkdirSync(dataDir, { recursive: true });
async function main() {
  if (!existsSync(path.join(appDir, 'server.js')))
    throw new Error('演示程序尚未打包，请先运行准备演示脚本。');
  const secretFile = path.join(dataDir, 'local-config.json');
  const secrets = existsSync(secretFile)
    ? JSON.parse(readFileSync(secretFile, 'utf8'))
    : { accessCode: randomBytes(12).toString('hex'), hashKey: randomBytes(32).toString('hex') };
  if (!existsSync(secretFile)) writeFileSync(secretFile, JSON.stringify(secrets), { mode: 0o600 });
  const databaseUrl = 'file:' + path.join(dataDir, 'demo.db').split(path.sep).join('/');
  const requireApp = createRequire(path.join(appDir, 'package.json'));
  const { PrismaClient } = requireApp('@prisma/client');
  const db = new PrismaClient({ datasources: { db: { url: databaseUrl } }, log: [] });
  try {
    await db.$queryRawUnsafe('PRAGMA journal_mode = WAL');
    await db.$executeRawUnsafe(
      'CREATE TABLE IF NOT EXISTS _DemoMigration (name TEXT NOT NULL PRIMARY KEY)',
    );
    const directory = path.join(root, 'prisma', 'migrations');
    for (const name of readdirSync(directory).sort()) {
      const file = path.join(directory, name, 'migration.sql');
      if (!existsSync(file)) continue;
      const applied = await db.$queryRawUnsafe(
        'SELECT name FROM _DemoMigration WHERE name = ?',
        name,
      );
      if (applied.length) continue;
      await db.$transaction(async (tx) => {
        for (const sql of readFileSync(file, 'utf8')
          .split(';')
          .map((part) => part.trim())
          .filter(Boolean))
          await tx.$executeRawUnsafe(sql);
        await tx.$executeRawUnsafe('INSERT INTO _DemoMigration (name) VALUES (?)', name);
      });
    }
  } finally {
    await db.$disconnect();
  }
  let port;
  const first = Number(process.env.DEMO_PORT || '4173');
  for (let candidate = first; candidate < first + 30; candidate++) {
    const available = await new Promise((resolve) => {
      const probe = net.createServer();
      probe.once('error', () => resolve(false));
      probe.listen(candidate, '127.0.0.1', () => probe.close(() => resolve(true)));
    });
    if (available) {
      port = candidate;
      break;
    }
  }
  if (!port) throw new Error('可用端口不足，请关闭之前打开的演示窗口再试。');
  const url = 'http://127.0.0.1:' + port;
  const env = {
    ...process.env,
    NODE_ENV: 'production',
    HOSTNAME: '127.0.0.1',
    PORT: String(port),
    DEMO_MODE: '1',
    DATABASE_URL: databaseUrl,
    UPLOAD_DIR: path.join(dataDir, 'uploads'),
    GROUP_TIMEZONE: 'Asia/Shanghai',
    MIN_PARTICIPANTS: '3',
    GROUP_ACCESS_CODE: secrets.accessCode,
    IDENTITY_HASH_KEY: secrets.hashKey,
  };
  console.log('正在启动同频比赛演示，请稍候…');
  const child = spawn(process.execPath, [path.join(appDir, 'server.js')], {
    cwd: appDir,
    env,
    windowsHide: true,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let exited = false;
  let failed = false;
  const logFile = path.join(dataDir, 'server.log');
  child.stdout.on('data', (chunk) => {
    appendFileSync(logFile, chunk);
    process.stdout.write(chunk);
  });
  child.stderr.on('data', (chunk) => {
    appendFileSync(logFile, chunk);
    process.stderr.write(chunk);
  });
  child.once('error', (error) => {
    exited = true;
    console.error('启动失败：' + error.message);
    process.exitCode = 1;
  });
  child.once('exit', (code) => {
    exited = true;
    process.exitCode = failed ? 1 : (code ?? 0);
  });
  const stop = () => {
    child.kill();
  };
  process.on('SIGINT', stop);
  process.on('SIGTERM', stop);
  if (process.send) {
    process.on('message', (message) => {
      if (message === 'stop') {
        stop();
        process.disconnect();
      }
    });
  }
  for (let i = 0; i < 160; i++) {
    if (exited) throw new Error('演示服务启动失败，详情见 .demo/server.log');
    try {
      const response = await fetch(url + '/api/v1/config', { signal: AbortSignal.timeout(1500) });
      if (response.ok) {
        console.log('演示已就绪：' + url + '/availability');
        console.log('无需访问码。请保留此窗口；结束演示时按 Ctrl+C。');
        if (!process.argv.includes('--no-open')) {
          const browser = spawn('cmd.exe', ['/d', '/c', 'start', '', url + '/availability'], {
            windowsHide: true,
            stdio: 'ignore',
          });
          browser.once('error', () => console.log('请手动在浏览器打开上方网址。'));
        }
        return;
      }
    } catch {
      /* Wait for this application only. */
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  failed = true;
  child.kill();
  throw new Error('启动等待超时，详情见 .demo/server.log');
}
main().catch((error) => {
  console.error(error instanceof Error ? error.message : '启动失败');
  process.exitCode = 1;
});
