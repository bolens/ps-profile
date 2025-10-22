. "$PSScriptRoot\..\profile.d\00-bootstrap.ps1"
Write-Output "Loaded bootstrap. Get-Command for Set-AgentModeAlias:"
Get-Command -Name Set-AgentModeAlias -ErrorAction SilentlyContinue | Format-List * -Force
$aliasName = "dbg_alias_$(Get-Random)"
try {
    $env:PS_PROFILE_DEBUG = '1'
    Write-Output "Attempting Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'"
    $res = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
    Write-Output "Result: $res"
} catch {
    Write-Output "Caught exception: $($_.Exception.Message)"
    Write-Output $_.Exception.ToString()
}
Write-Output "After attempt, Get-Command:" 
Get-Command -Name $aliasName -ErrorAction SilentlyContinue | Format-List * -Force
Get-Alias -Name $aliasName -ErrorAction SilentlyContinue | Format-List * -Force
