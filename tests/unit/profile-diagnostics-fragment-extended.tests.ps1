<#
tests/unit/profile-diagnostics-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/diagnostics.ps1'
}
Describe 'profile.d/diagnostics.ps1 extended scenarios' {
    It 'Declares standard tier with bootstrap dependency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Loads diagnostics-profile module from diagnostics-modules/core' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'diagnostics-modules'
        $c | Should -Match 'diagnostics-profile\.ps1'
    }
    It 'Uses Import-FragmentModule with manual fallback loading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Import-FragmentModule'
        $c | Should -Match 'Fallback: manual loading'
    }
}
