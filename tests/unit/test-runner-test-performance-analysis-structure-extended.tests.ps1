<#
tests/unit/test-runner-test-performance-analysis-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestPerformanceAnalysis.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestPerformanceAnalysis.psm1 structure extended scenarios' {
    It 'Documents test performance analysis module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestPerformanceAnalysis.psm1'
        $c | Should -Match 'performance analysis'
    }
    It 'Defines Get-PerformanceAnalysis helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-PerformanceAnalysis'
    }
    It 'Exports performance analysis function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Get-PerformanceAnalysis'
    }
}

