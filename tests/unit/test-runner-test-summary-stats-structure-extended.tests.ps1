<#
tests/unit/test-runner-test-summary-stats-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestSummaryStats.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestSummaryStats.psm1 structure extended scenarios' {
    It 'Documents enhanced summary statistics utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Enhanced test summary statistics utilities'
        $c | Should -Match 'TestSummaryStats.psm1'
    }
    It 'Defines summary statistics helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestSummaryStatistics'
        $c | Should -Match 'Show-TestSummaryStatistics'
        $c | Should -Match 'ShowSlowest'
    }
    It 'Imports Logging and Locale modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Logging.psm1'
        $c | Should -Match 'Locale.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
