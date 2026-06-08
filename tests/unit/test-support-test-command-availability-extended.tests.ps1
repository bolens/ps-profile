<#
tests/unit/test-support-test-command-availability-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestCommandAvailability.ps1'
}
Describe 'tests/TestSupport/TestCommandAvailability.ps1 extended scenarios' {
    It 'Documents command availability stubs without Pester Mock' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestCommandAvailability.ps1'
        $c | Should -Match 'Command availability stubs'
    }
    It 'Defines Register-TestCommandAvailabilityStub' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-TestCommandAvailabilityStub'
        $c | Should -Match 'Set-TestCommandAvailabilityState'
    }
    It 'Defines Clear-TestCommandAvailabilityStub cleanup' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Clear-TestCommandAvailabilityStub'
    }
}

