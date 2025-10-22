$tempLog = Join-Path $env:TEMP 'set_agentmode_debug.log'
$repoLog = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..' | Resolve-Path | ForEach-Object { Join-Path $_ 'set_agentmode_debug.log' }
Write-Host "Temp log: $tempLog"
if (Test-Path $tempLog) { Get-Content $tempLog } else { Write-Host 'No temp log found' }
Write-Host "Repo log(s):"
foreach ($p in $repoLog) { Write-Host "- $p"; if (Test-Path $p) { Get-Content $p } else { Write-Host '  (not found)' } }
