<#
tests/unit/profile-env-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/env.ps1'
}
Describe 'profile.d/env.ps1 extended scenarios' {
    It 'Declares essential tier with bootstrap dependency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap'
    }
    It 'Uses Test-FragmentLoaded for idempotent loading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-FragmentLoaded'
        $c | Should -Match "FragmentName 'env'"
    }
    It 'Loads EnvFile.psm1 and calls Initialize-EnvFiles' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'EnvFile\.psm1'
        $c | Should -Match 'Initialize-EnvFiles'
    }
    It 'Sets editor and git defaults only when unset' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'overwrite existing values'
    }
}
