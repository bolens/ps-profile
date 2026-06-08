<#
tests/unit/profile-local-overrides-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/local-overrides.ps1'
}
Describe 'profile.d/local-overrides.ps1 extended scenarios' {
    It 'Declares standard tier for machine-specific overrides' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Gates loading on PS_PROFILE_ENABLE_LOCAL_OVERRIDES environment flag' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PS_PROFILE_ENABLE_LOCAL_OVERRIDES'
        $c | Should -Match "PS_PROFILE_ENABLE_LOCAL_OVERRIDES -eq '1'"
    }
    It 'Resolves local-overrides.ps1 via ProfileFragmentRoot or PSScriptRoot' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ProfileFragmentRoot'
        $c | Should -Match 'local-overrides.ps1'
    }
}
