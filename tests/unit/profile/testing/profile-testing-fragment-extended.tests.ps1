<#
tests/unit/profile-testing-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/testing.ps1'
}
Describe 'profile.d/testing.ps1 extended scenarios' {
    It 'Declares standard tier for testing and development environments' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: testing, development'
    }
    It 'Loads testing-frameworks module from dev-tools-modules/build' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'dev-tools-modules'
        $c | Should -Match 'testing-frameworks\.ps1'
    }
    It 'Uses Import-FragmentModule with CacheResults when available' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Import-FragmentModule'
        $c | Should -Match 'CacheResults'
    }
}
