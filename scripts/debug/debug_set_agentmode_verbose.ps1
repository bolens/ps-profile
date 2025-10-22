

. $bootstrapPath Join-Path $repoRoot 'profile.d\00-bootstrap.ps1'

Write-Host 'Loading bootstrap'
. $bootstrapPath
Write-Host 'Inspecting function definition of Set-AgentModeFunction'
Get-Command Set-AgentModeFunction | Format-List *

$b = { return 'ok' }
Write-Host "Get-Command -Name test_agent_fn ->"; Get-Command test_agent_fn -ErrorAction SilentlyContinue | Format-List *
Write-Host "Test-Path Function:test_agent_fn ->"; Test-Path Function:\test_agent_fn

Write-Host 'Calling Set-AgentModeFunction...'
Set-AgentModeFunction -Name 'test_agent_fn' -Body $b

Write-Host 'After call: Get-Item Function:'
Get-Item Function:\test_agent_fn -ErrorAction SilentlyContinue | Format-List *
Write-Host 'After call: Get-Command test_agent_fn'
Get-Command test_agent_fn -ErrorAction SilentlyContinue | Format-List *
Write-Host 'Invoke attempt:'
try { & test_agent_fn; Write-Host 'invoked' } catch { Write-Host 'invoke failed: ' + $_.Exception.Message }
