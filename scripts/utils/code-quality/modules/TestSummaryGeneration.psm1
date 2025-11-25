<#
scripts/utils/code-quality/modules/TestSummaryGeneration.psm1

.SYNOPSIS
    Test execution summary generation utilities.

.DESCRIPTION
    Provides functions for generating test execution summaries with performance metrics.
#>

<#
.SYNOPSIS
    Generates a test execution summary with performance metrics.

.DESCRIPTION
    Creates a comprehensive summary of test execution including
    performance metrics, environment information, and recommendations.

.PARAMETER TestResult
    The Pester test result object.

.PARAMETER PerformanceData
    Performance metrics from test execution.

.PARAMETER EnvironmentInfo
    Environment information.

.OUTPUTS
    Test execution summary object
#>
function New-TestExecutionSummary {
    param(
        [Parameter(Mandatory)]
        $TestResult,

        $PerformanceData,

        $EnvironmentInfo
    )

    $summary = @{
        Timestamp       = Get-Date
        Environment     = $EnvironmentInfo
        TestResults     = @{
            Total        = $TestResult.TotalCount
            Passed       = $TestResult.PassedCount
            Failed       = $TestResult.FailedCount
            Skipped      = $TestResult.SkippedCount
            Inconclusive = $TestResult.InconclusiveCount
            NotRun       = $TestResult.NotRunCount
            Duration     = $TestResult.Time
        }
        Success         = $TestResult.FailedCount -eq 0
        Performance     = $PerformanceData
        Recommendations = @()
    }

    # Generate recommendations based on results
    if ($TestResult.FailedCount -gt 0) {
        $summary.Recommendations += "Review $($TestResult.FailedCount) failed tests"
    }

    if ($PerformanceData -and $PerformanceData.Performance.Duration.TotalSeconds -gt 300) {
        $summary.Recommendations += "Consider parallel execution for long-running tests ($([Math]::Round($PerformanceData.Performance.Duration.TotalSeconds))s total)"
    }

    if ($PerformanceData -and $PerformanceData.Performance.PeakMemoryMB -gt 1000) {
        $summary.Recommendations += "High memory usage detected ($([Math]::Round($PerformanceData.Performance.PeakMemoryMB))MB peak)"
    }

    if ($EnvironmentInfo.IsCI -and $TestResult.SkippedCount -gt 0) {
        $summary.Recommendations += "Review $($TestResult.SkippedCount) skipped tests in CI environment"
    }

    return $summary
}

Export-ModuleMember -Function New-TestExecutionSummary

