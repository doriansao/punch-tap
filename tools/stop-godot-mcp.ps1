$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$pidPath = Join-Path $projectPath '.setup\editor.pid'
if (!(Test-Path -LiteralPath $pidPath)) { Write-Output 'No managed server PID found.'; exit 0 }
$serverPid = [int](Get-Content -LiteralPath $pidPath)
$process = Get-CimInstance Win32_Process -Filter "ProcessId = $serverPid"
if (!$process) { Write-Output 'Managed server already stopped.'; exit 0 }
if ($process.Name -notmatch '^Godot_' -or !$process.CommandLine.Contains($projectPath) -or !$process.CommandLine.Contains('--headless')) {
    throw 'PID no longer belongs to the Punch Tap headless editor; refusing to stop it.'
}
Stop-Process -Id $serverPid
Write-Output 'Punch Tap! headless MCP editor stopped.'
