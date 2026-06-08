<#
tests/unit/profile-database-fragment-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/database.ps1'
}
Describe 'profile.d/database.ps1 extended scenarios' {
    It 'Declares standard tier for server and development database helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: server, development'
    }
    It 'Defines Connect-Database with Test-CachedCommand guarded client selection' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Connect-Database'
        $c | Should -Match 'Test-CachedCommand'
    }
    It 'Registers db-connect alias targeting Connect-Database' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'db-connect'"
        $c | Should -Match 'Connect-Database'
    }
}
