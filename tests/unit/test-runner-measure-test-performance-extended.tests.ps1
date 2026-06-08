<#
tests/unit/test-runner-measure-test-performance-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Measure-TestPerformance metrics collection.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestPerformanceMonitoring.psm1') -Force -Global
}

Describe 'Measure-TestPerformance extended scenarios' {
    Context 'Measure-TestPerformance' {
        It 'Records start and end timestamps around execution' {
            $result = Measure-TestPerformance -ScriptBlock {
                Start-Sleep -Milliseconds 50
                return 'timed'
            }

            $result.Result | Should -Be 'timed'
            $result.Performance.StartTime | Should -Not -BeNullOrEmpty
            $result.Performance.EndTime | Should -Not -BeNullOrEmpty
            $result.Performance.EndTime | Should -BeGreaterThan $result.Performance.StartTime
        }

        It 'Preserves complex result objects from the monitored script block' {
            $payload = @{
                PassedCount = 3
                FailedCount = 0
                Tags        = @('Unit', 'Fast')
            }

            $result = Measure-TestPerformance -ScriptBlock { return $payload }

            $result.Result.PassedCount | Should -Be 3
            $result.Result.Tags | Should -Contain 'Unit'
        }

        It 'Leaves memory metrics at zero when tracking is disabled' {
            $result = Measure-TestPerformance -ScriptBlock {
                $data = 1..500
                return $data.Count
            }

            $result.Result | Should -Be 500
            $result.Performance.PeakMemoryMB | Should -Be 0
            $result.Performance.AverageMemoryMB | Should -Be 0
        }

        It 'Propagates exceptions thrown by the monitored script block' {
            { Measure-TestPerformance -ScriptBlock { throw 'measurement failure' } } |
                Should -Throw '*measurement failure*'
        }
    }
}
