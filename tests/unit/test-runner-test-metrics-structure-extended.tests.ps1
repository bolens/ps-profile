<#
tests/unit/test-runner-test-metrics-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestMetrics.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestMetrics.psm1 structure extended scenarios' {
    It 'Documents test metrics and scoring utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test metrics and scoring utilities'
        $c | Should -Match 'TestMetrics.psm1'
    }
    It 'Defines coverage and stability scoring helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Calculate-TestCoverage'
        $c | Should -Match 'Calculate-StabilityScore'
        $c | Should -Match 'Calculate-PerformanceScore'
    }
    It 'Defines performance grade helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-PerformanceGrade'
        $c | Should -Match 'Export-ModuleMember'
    }
}
