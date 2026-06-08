<#
tests/unit/profile-main-loader-fragment-config-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 fragment configuration extended scenarios' {
    It 'Loads ProfileFragmentConfig for fragment settings' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'ProfileFragmentConfig.psm1'
        $c | Should -Match 'Initialize-FragmentConfiguration'
        $c | Should -Match 'FragmentConfig.psm1'
    }
    It 'Exposes environment sets and feature flags from config' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'environmentSets'
        $c | Should -Match 'featureFlags'
        $c | Should -Match 'loadOrderOverride'
    }
    It 'Wires fragment error handling module path' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'FragmentErrorHandling.psm1'
        $c | Should -Match 'fragmentErrorHandlingModule'
        $c | Should -Match 'FragmentErrorHandlingModuleExists'
    }
}
