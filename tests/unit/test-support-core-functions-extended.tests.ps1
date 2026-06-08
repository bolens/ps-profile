<#
tests/unit/test-support-core-functions-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestSupportCoreFunctions.ps1'
}
Describe 'tests/TestSupport/TestSupportCoreFunctions.ps1 extended scenarios' {
    It 'Documents canonical TestSupport helper functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestSupportCoreFunctions.ps1'
        $c | Should -Match 'TestSupport helpers restored'
    }
    It 'Defines Mark-TestCommandsUnavailable for command stubs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Mark-TestCommandsUnavailable'
        $c | Should -Match 'Set-TestCommandAvailabilityState'
        $c | Should -Match 'TestCachedCommandCache'
    }
    It 'Defines Register-TestFragmentAliases and fragment import helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-TestFragmentAliases'
        $c | Should -Match 'Import-ProfileFragmentWithShadowedCommands'
    }
}

