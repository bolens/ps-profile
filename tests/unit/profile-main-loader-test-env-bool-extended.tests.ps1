<#
tests/unit/profile-main-loader-test-env-bool-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 Test-EnvBool fallback extended scenarios' {
    It 'Documents inline Test-EnvBool fallback helper' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'function Test-EnvBool'
        $c | Should -Match 'normalize boolean environment variables'
        $c | Should -Match '''1'', ''true'''
    }
    It 'Uses Test-EnvBool for parallel loading flag' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'PS_PROFILE_PARALLEL_LOADING'
        $c | Should -Match 'enableParallelLoading = Test-EnvBool'
    }
    It 'Treats empty env values as false' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'IsNullOrWhiteSpace'
        $c | Should -Match 'return .+false'
        $c | Should -Match 'ToLowerInvariant'
    }
}
