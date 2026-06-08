<#
tests/unit/profile-database-clients-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/database-clients.ps1'
}
Describe 'profile.d/database-clients.ps1 extended scenarios' {
    It 'Declares standard tier for database GUI and CLI clients' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'mongodb-compass'
        $c | Should -Match 'dbeaver'
    }
    It 'Defines Start-MongoDbCompass with mongodb-compass alias' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-MongoDbCompass'
        $c | Should -Match "Set-AgentModeAlias -Name 'mongodb-compass'"
    }
    It 'Uses Test-FragmentLoaded guard before registering client launchers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'database-clients'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'database-clients'"
    }
}
