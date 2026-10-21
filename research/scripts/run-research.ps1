param(
 [string[]]$Cases = @('idle','left_body','right_body','left_head','right_head','dodge_left','dodge_right','down','hold_left'),
 [string]$Rom = 'G:\Programming\punch-out-ai\rom\punch-out.nes'
)
$ErrorActionPreference = 'Stop'
$researchRoot = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $researchRoot 'tools\mesen\Mesen.exe'
$provenance = Get-Content (Join-Path $researchRoot 'evidence\provenance.json') -Raw | ConvertFrom-Json
if ((Get-FileHash -LiteralPath $Rom).Hash -ne $provenance.files[0].sha256) {
 throw 'ROM differs from the researched revision.'
}
foreach ($case in $Cases) {
 if ($case -notmatch '^[a-z_]+$') { throw 'Invalid experiment name.' }
 $script = Join-Path $PSScriptRoot "$case.lua"
 if (-not (Test-Path -LiteralPath $script)) { throw "Missing script $script" }
 $extra = switch ($case) {
  'sprites_only' { '--Nes.DisableBackground=true' }
  'background_only' { '--Nes.DisableSprites=true' }
  default { '' }
 }
 $arguments = '--testRunner "{0}" "{1}" --timeout=180 {2}' -f $Rom,$script,$extra
 $process = Start-Process -FilePath $exe -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru
 if ($process.ExitCode -ne 0) { throw "$case failed: exit $($process.ExitCode)" }
 Write-Output "$case completed"
}
