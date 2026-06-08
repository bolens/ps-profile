<#
tests/unit/test-runner-comprehensive-reporting.tests.ps1

.SYNOPSIS
    Unit tests for TestComprehensiveReporting module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestComprehensiveReporting.psm1') -Force -Global

    function script:New-MockTestResult {
        return [pscustomobject]@{
            TotalCount   = 10
            PassedCount  = 8
            FailedCount  = 2
            SkippedCount = 0
            Time         = [TimeSpan]::FromSeconds(12)
            FailedTests  = @(
                [pscustomobject]@{
                    Name        = 'Failed case'
                    File        = 'sample.tests.ps1'
                    ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                        [Exception]::new('boom'),
                        'TestFailure',
                        'NotSpecified',
                        $null
                    )
                }
            )
        }
    }
}

Describe 'TestComprehensiveReporting Module' {
    Context 'New-ComprehensiveTestReport' {
        It 'Builds summary report with quality metrics' {
            $testResult = New-MockTestResult
            $performance = @{
                Duration        = [TimeSpan]::FromSeconds(30)
                PeakMemoryMB    = 256
                AverageMemoryMB = 200
                CPUUsage        = 35
            }
            $environment = @{
                IsCI = $false
            }

            $report = New-ComprehensiveTestReport -TestResult $testResult -PerformanceData $performance -EnvironmentInfo $environment

            $report.ReportType | Should -Be 'Summary'
            $report.TestResults.TotalTests | Should -Be 10
            $report.TestResults.SuccessRate | Should -Be 80
            $report.Performance.PerformanceGrade | Should -Be 'A'
            $report.QualityMetrics.OverallQuality | Should -BeGreaterThan 0
            @($report.Recommendations).Count | Should -BeGreaterThan 0
        }

        It 'Includes trend analysis when historical data is provided' {
            $testResult = New-MockTestResult
            $historical = @(
                @{ FailedCount = 1; TotalCount = 10; Time = [TimeSpan]::FromSeconds(8) }
            )

            $report = New-ComprehensiveTestReport -TestResult $testResult -HistoricalData $historical

            $report.Trends | Should -Not -BeNullOrEmpty
            $report.Trends.AverageFailureRate | Should -Be 0.2
        }
    }
}
