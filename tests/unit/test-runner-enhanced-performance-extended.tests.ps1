<#
tests/unit/test-runner-enhanced-performance-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestEnhancedPerformance helpers.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestPerformanceMonitoring.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestEnhancedPerformance.psm1') -Force -Global
}

Describe 'TestEnhancedPerformance extended scenarios' {
    Context 'Measure-EnhancedPerformance' {
        It 'Returns basic metrics without DetailedMetrics' {
            $result = Measure-EnhancedPerformance -ScriptBlock {
                return 42
            }

            $result.Enhanced | Should -Be $true
            $result.Result | Should -Be 42
            $result.Metrics.Duration | Should -Not -BeNullOrEmpty
            $result.Metrics.MemoryMetrics.Count | Should -Be 0
        }

        It 'Propagates script block return values on success' {
            $payload = [PSCustomObject]@{ Value = 'payload' }
            $result = Measure-EnhancedPerformance -ScriptBlock { return $payload }
            $result.Result.Value | Should -Be 'payload'
        }

        It 'Surfaces performance degradation details when execution exceeds baseline' {
            $baseline = @{
                TestSummary = @{
                    Duration = '00:00:00.001'
                }
            }

            $result = Measure-EnhancedPerformance -ScriptBlock {
                Start-Sleep -Milliseconds 250
                return 'done'
            } -DetailedMetrics -BaselineData $baseline

            $result.Metrics.PerformanceDegradation.IsDegraded | Should -Be $true
            $result.Metrics.PerformanceDegradation.BaselineDuration | Should -Not -BeNullOrEmpty
        }

        It 'Tracks memory deltas when DetailedMetrics is enabled' {
            $result = Measure-EnhancedPerformance -ScriptBlock {
                $null = 1..5000
                return 'allocated'
            } -DetailedMetrics

            $result.Metrics.MemoryMetrics.InitialMB | Should -BeGreaterThan 0
            $result.Metrics.MemoryMetrics.FinalMB | Should -BeGreaterThan 0
            $result.Metrics.MemoryMetrics.ContainsKey('DeltaMB') | Should -Be $true
        }

        It 'Includes thread metrics in enhanced results' {
            $result = Measure-EnhancedPerformance -ScriptBlock { 'threads' } -DetailedMetrics
            $result.Metrics.ThreadMetrics.FinalCount | Should -BeGreaterThan 0
            $result.Metrics.MemoryMetrics.FinalMB | Should -BeGreaterThan 0
        }
    }
}
