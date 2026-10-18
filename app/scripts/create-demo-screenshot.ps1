$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$directory = Join-Path $root 'demo-assets'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$bitmap = New-Object System.Drawing.Bitmap(1240, 1050)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::White)
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$font = New-Object System.Drawing.Font('Microsoft YaHei', 26)
$lines = @(
  '姓名：小林',
  '周一 09:00-10:30 高等数学',
  '周一 10:00-11:00 实验课',
  '周二 14:00-16:00 小组讨论',
  '周三 18:00-20:00 有空',
  '',
  '姓名：小陈',
  '周一 08:30-10:00 英语课',
  '周三 18:30-20:30 有空',
  '周五 15:00-17:00 社团活动'
)
for ($i = 0; $i -lt $lines.Count; $i++) {
  $graphics.DrawString($lines[$i], $font, [System.Drawing.Brushes]::Black, 65, (50 + $i * 85))
}
$bitmap.Save((Join-Path $directory 'schedule-demo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$font.Dispose()
$graphics.Dispose()
$bitmap.Dispose()
Write-Output 'demo-assets/schedule-demo.png'
