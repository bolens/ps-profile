<#
tests/unit/test-support-test-command-availability-extended.tests.ps1
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

