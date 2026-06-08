<#
tests/unit/test-runner-baseline-comparison-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/BaselineComparison.psm1'
}
Describe 'scripts/utils/code-quality/modules/BaselineComparison.psm1 structure extended scenarios' {
    It 'Documents baseline comparison for performance tests' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'BaselineComparison.psm1'
        $c | Should -Match 'baseline'
    }
    It 'Compares current metrics against stored baselines' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Compare'
        $c | Should -Match 'Baseline'
        $c | Should -Match 'Regression'
    }
    It 'Exports baseline comparison helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
    }
}

