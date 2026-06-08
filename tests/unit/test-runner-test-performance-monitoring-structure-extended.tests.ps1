<#
tests/unit/test-runner-test-performance-monitoring-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestPerformanceMonitoring.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestPerformanceMonitoring.psm1 structure extended scenarios' {
    It 'Documents test performance monitoring utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test performance monitoring utilities'
        $c | Should -Match 'TestPerformanceMonitoring.psm1'
    }
    It 'Defines Measure-TestPerformance helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Measure-TestPerformance'
        $c | Should -Match 'TrackMemory'
        $c | Should -Match 'TrackCPU'
    }
    It 'Defines Invoke-TestExecutionWithPerformance wrapper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-TestExecutionWithPerformance'
        $c | Should -Match 'Logging.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
