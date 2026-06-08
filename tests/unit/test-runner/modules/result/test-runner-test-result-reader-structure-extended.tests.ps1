<#
tests/unit/test-runner-test-result-reader-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestResultReader.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestResultReader.psm1 structure extended scenarios' {
    It 'Documents test result reading utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test result reading utilities'
        $c | Should -Match 'TestResultReader.psm1'
    }
    It 'Defines failed test extraction helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-FailedTestsFromLastRun'
        $c | Should -Match 'Get-TestFilesFromFailedTestNames'
    }
    It 'Exports result reader functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'FailedTests'
    }
}
