<#
tests/unit/test-runner-enhanced-performance.tests.ps1

.SYNOPSIS
    Unit tests for TestEnhancedPerformance module.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestPerformanceMonitoring.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestEnhancedPerformance.psm1') -Force -Global
}

Describe 'TestEnhancedPerformance Module' {
    Context 'Measure-EnhancedPerformance' {
        It 'Executes script block and returns enhanced metrics' {
            $result = Measure-EnhancedPerformance -ScriptBlock {
                return 'enhanced-result'
            }

            $result.Enhanced | Should -Be $true
            $result.Result | Should -Be 'enhanced-result'
            $result.Metrics.Duration | Should -Not -BeNullOrEmpty
            $result.Metrics.ThreadMetrics.FinalCount | Should -BeGreaterThan 0
        }

        It 'Collects detailed memory metrics when requested' {
            $result = Measure-EnhancedPerformance -ScriptBlock {
                $data = 1..5000
                return $data.Count
            } -DetailedMetrics

            $result.Metrics.MemoryMetrics.InitialMB | Should -BeGreaterThan 0
            $result.Metrics.MemoryMetrics.FinalMB | Should -BeGreaterThan 0
        }

        It 'Compares duration against baseline data' {
            $baseline = @{
                TestSummary = @{
                    Duration = '00:00:10'
                }
            }

            $result = Measure-EnhancedPerformance -ScriptBlock {
                return 'done'
            } -DetailedMetrics -BaselineData $baseline

            $result.Metrics.PerformanceDegradation | Should -Not -BeNullOrEmpty
            $result.Metrics.PerformanceDegradation.BaselineDuration | Should -Not -BeNullOrEmpty
            $result.Metrics.PerformanceDegradation.CurrentDuration | Should -Not -BeNullOrEmpty
            $result.Metrics.PerformanceDegradation.ContainsKey('IsDegraded') | Should -Be $true
        }
    }
}
