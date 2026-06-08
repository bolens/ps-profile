<#
tests/unit/test-support-core-functions-extended.tests.ps1
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

