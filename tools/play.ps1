param([string]$GodotPath = 'G:\Programming\Tools\Godot\Godot_v4.7.2-stable_mono_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
Start-Process -FilePath $GodotPath -ArgumentList @('--path', ('"' + $projectPath + '"')) -WindowStyle Hidden
