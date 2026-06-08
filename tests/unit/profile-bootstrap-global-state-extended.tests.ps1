<#
tests/unit/profile-bootstrap-global-state-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/GlobalState.ps1'
}
Describe 'profile.d/bootstrap/GlobalState.ps1 extended scenarios' {
    It 'Documents global state variable initialization for bootstrap' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Global state variable initialization'
        $c | Should -Match 'PSProfileBootstrapInitialized'
    }
    It 'Initializes thread-safe TestCachedCommandCache and AssumedAvailableCommands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestCachedCommandCache'
        $c | Should -Match 'AssumedAvailableCommands'
        $c | Should -Match 'ConcurrentDictionary'
    }
    It 'Defines Test-EnvBool and Get-ProfileDebugLevel helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-EnvBool'
        $c | Should -Match 'Get-ProfileDebugLevel'
        $c | Should -Match 'BootstrapRoot'
    }
}
