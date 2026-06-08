<#
tests/unit/profile-utilities-network-advanced-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/network/utilities-network-advanced.ps1'
}
Describe 'profile.d/utilities-modules/network/utilities-network-advanced.ps1 extended scenarios' {
    It 'Documents advanced network utilities with retry and timeout handling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Advanced network utility functions'
        $c | Should -Match 'error recovery and timeout handling'
    }
    It 'Defines Invoke-WithRetry and Invoke-HttpRequestWithRetry helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-WithRetry'
        $c | Should -Match 'Invoke-HttpRequestWithRetry'
        $c | Should -Match 'Test-NetworkConnectivity'
        $c | Should -Match 'NetworkUtilsLoaded'
    }
    It 'Imports Retry module and sets NetworkUtilsLoaded global flag' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Retry.psm1'
        $c | Should -Match 'Resolve-HostWithRetry'
        $c | Should -Match "Set-Variable -Name 'NetworkUtilsLoaded'"
    }
}
