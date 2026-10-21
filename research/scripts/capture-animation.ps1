param([string[]]$Cases = @('visual_audit','normal_knockdowns','player_getup_wide','idle_long'))
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$rom = 'G:\Programming\punch-out-ai\rom\punch-out.nes'
if ((Get-FileHash -LiteralPath $rom).Hash -ne '60EF51F55F6ADDB7A1893F816AAD75EE3E146DD646958A865D3BECE5B429B600') { throw 'Unexpected ROM' }
foreach ($case in $Cases) {
 foreach ($layer in @('full','player','opponent')) {
  $flag = switch ($layer) { 'player' {'--Nes.DisableSprites=true'} 'opponent' {'--Nes.DisableBackground=true'} default {''} }
  $script = Join-Path $PSScriptRoot "anim_${case}_${layer}.lua"
  $p = Start-Process -FilePath (Join-Path $root 'tools\mesen\Mesen.exe') -ArgumentList ('--testRunner "{0}" "{1}" --timeout=180 {2}' -f $rom,$script,$flag) -WindowStyle Hidden -Wait -PassThru
  if ($p.ExitCode -ne 0) {throw "$case $layer failed"}
  Write-Output "$case $layer completed"
 }
}
