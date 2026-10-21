param([string]$GodotPath = 'G:\Programming\Tools\Godot\Godot_v4.7.2-stable_mono_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$cli = Join-Path $PSScriptRoot 'gdmcp\gdmcp.exe'
$existing = & $cli --json doctor 2>$null | ConvertFrom-Json
if ($existing.editor_connected) {
    if ($existing.project_path.TrimEnd('/').Replace('/', '\') -ne $projectPath) {
        throw "Port 9080 belongs to a different Godot project: $($existing.project_path)"
    }
    Write-Output 'Punch Tap! MCP is already running.'
    exit 0
}
New-Item -ItemType Directory -Path (Join-Path $projectPath '.setup') -Force | Out-Null
$process = Start-Process -FilePath $GodotPath -ArgumentList @('--headless', '--editor', '--path', ('"' + $projectPath + '"'), '--', '--mcp-server', '--mcp-port=9080') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $projectPath '.setup\editor.stdout.log') -RedirectStandardError (Join-Path $projectPath '.setup\editor.stderr.log') -PassThru
$process.Id | Set-Content (Join-Path $projectPath '.setup\editor.pid')
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Milliseconds 500
    $health = & $cli --json doctor 2>$null | ConvertFrom-Json
    if ($health.editor_connected) {
        if ($health.project_path.TrimEnd('/').Replace('/', '\') -ne $projectPath) { throw 'Unexpected project on MCP port.' }
        $health | ConvertTo-Json
        exit 0
    }
    if ($process.HasExited) { throw 'Godot exited. Check .setup/editor.stderr.log.' }
}
throw 'MCP did not become ready within 15 seconds. Check .setup logs.'
