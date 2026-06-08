<#
tests/unit/profile-build-tools-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/build-tools.ps1'
}
Describe 'profile.d/build-tools.ps1 extended scenarios' {
    It 'Declares standard tier for web and development environments' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Loads build-tools module from dev-tools-modules/build' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'dev-tools-modules'
        $c | Should -Match 'build-tools\.ps1'
    }
    It 'Uses Import-FragmentModule with manual fallback when helper is unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Import-FragmentModule'
        $c | Should -Match 'Fallback: manual loading'
    }
}
