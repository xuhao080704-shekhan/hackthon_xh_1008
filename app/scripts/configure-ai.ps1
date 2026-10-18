param([string]$ConfigRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$configPath = Join-Path ([System.IO.Path]::GetFullPath($ConfigRoot)) '.env'
$content = if (Test-Path -LiteralPath $configPath) { [System.IO.File]::ReadAllText($configPath) } else { '' }
function Read-Setting([string]$Name) {
  $match = [regex]::Match($content, '(?m)^' + [regex]::Escape($Name) + '\s*=\s*"([^"\r\n]*)"\s*$')
  if ($match.Success) { return $match.Groups[1].Value }
  return ''
}
$form = New-Object System.Windows.Forms.Form
$form.Text = '同频 · AI 配置（仅保存在这台电脑）'
$form.ClientSize = New-Object System.Drawing.Size(590, 390)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 10)
$intro = New-Object System.Windows.Forms.Label
$intro.Location = New-Object System.Drawing.Point(24, 18)
$intro.Size = New-Object System.Drawing.Size(540, 58)
$intro.Text = '填写服务商给你的三项信息，密钥不会发送给浏览器。' + [Environment]::NewLine + '生成档案需要联网，请选择支持图片和 JSON 输出的模型。'
$form.Controls.Add($intro)
$fields = @{}
$definitions = @(@('AI_API_BASE_URL', 'API 地址（含 /v1 等服务商路径）'), @('AI_MODEL', '模型名称'), @('AI_API_KEY', 'API 密钥（隐藏显示；留空保留已保存密钥）'))
for ($index = 0; $index -lt $definitions.Count; $index++) {
  $name = $definitions[$index][0]
  $label = New-Object System.Windows.Forms.Label
  $label.Location = New-Object System.Drawing.Point(24, (82 + $index * 72))
  $label.Size = New-Object System.Drawing.Size(540, 24)
  $label.Text = $definitions[$index][1]
  $form.Controls.Add($label)
  $inputBox = New-Object System.Windows.Forms.TextBox
  $inputBox.Location = New-Object System.Drawing.Point(24, (108 + $index * 72))
  $inputBox.Size = New-Object System.Drawing.Size(540, 29)
  if ($name -eq 'AI_API_KEY') { $inputBox.UseSystemPasswordChar = $true }
  else { $inputBox.Text = Read-Setting $name }
  if ($name -eq 'AI_API_BASE_URL' -and -not $inputBox.Text) { $inputBox.Text = 'https://api.openai.com/v1' }
  $fields[$name] = $inputBox
  $form.Controls.Add($inputBox)
}
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = '保存配置'
$saveButton.Location = New-Object System.Drawing.Point(320, 326)
$saveButton.Size = New-Object System.Drawing.Size(118, 38)
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = '取消'
$cancelButton.Location = New-Object System.Drawing.Point(448, 326)
$cancelButton.Size = New-Object System.Drawing.Size(116, 38)
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($saveButton)
$form.Controls.Add($cancelButton)
$form.CancelButton = $cancelButton
$saveButton.Add_Click({
  try {
    $values = @{}
    foreach ($name in @('AI_API_BASE_URL', 'AI_MODEL', 'AI_API_KEY')) {
      $value = $fields[$name].Text.Trim()
      if ($name -eq 'AI_API_KEY' -and -not $value) { $value = Read-Setting $name }
      if (-not $value -or $value.Contains('"') -or $value.Contains([char]13) -or $value.Contains([char]10) -or $value.Contains('$') -or $value.Contains('\')) { throw '请完整填写三项信息。内容不能包含引号、换行、反斜线或 $ 符号。' }
      $values[$name] = $value
    }
    $uri = $null
    if (-not [Uri]::TryCreate($values['AI_API_BASE_URL'], [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -notin @('http', 'https') -or $uri.UserInfo -or $uri.Query -or $uri.Fragment) { throw 'API 地址格式不正确，请填写服务商提供的完整 HTTP(S) 地址。' }
    if ($uri.Scheme -ne 'https' -and $uri.Host -notin @('localhost', '127.0.0.1', '::1')) { throw '远程 AI 服务地址请使用 HTTPS。' }
    $updated = $content
    foreach ($name in @('AI_API_BASE_URL', 'AI_MODEL', 'AI_API_KEY')) {
      $pattern = '(?m)^' + [regex]::Escape($name) + '\s*=.*$'
      $line = $name + '="' + $values[$name] + '"'
      if ([regex]::IsMatch($updated, $pattern)) { $updated = [regex]::Replace($updated, $pattern, $line) }
      else { $updated = $updated.TrimEnd() + [Environment]::NewLine + $line + [Environment]::NewLine }
    }
    [System.IO.File]::WriteAllText($configPath, $updated, (New-Object System.Text.UTF8Encoding($false)))
    [System.Windows.Forms.MessageBox]::Show('已保存。请关闭演示启动窗口并重新双击启动，再试一次档案生成。请勿把 .env 文件发给其他人。', '保存成功') | Out-Null
    $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Close()
  } catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, '配置未保存') | Out-Null
  }
})
[void]$form.ShowDialog()
$form.Dispose()
