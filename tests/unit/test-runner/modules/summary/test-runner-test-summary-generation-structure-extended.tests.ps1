<#
tests/unit/test-runner-test-summary-generation-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestSummaryGeneration.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestSummaryGeneration.psm1 structure extended scenarios' {
    It 'Documents test execution summary generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test execution summary generation utilities'
        $c | Should -Match 'TestSummaryGeneration.psm1'
    }
    It 'Defines New-TestExecutionSummary helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-TestExecutionSummary'
        $c | Should -Match 'PerformanceData'
        $c | Should -Match 'EnvironmentInfo'
    }
    It 'Exports summary generation function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Function New-TestExecutionSummary'
        $c | Should -Match 'InconclusiveCount'
    }
}
