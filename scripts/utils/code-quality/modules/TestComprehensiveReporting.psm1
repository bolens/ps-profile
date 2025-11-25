<#
scripts/utils/code-quality/modules/TestComprehensiveReporting.psm1

.SYNOPSIS
    Comprehensive test reporting utilities.

.DESCRIPTION
    Provides functions for generating comprehensive test execution reports combining
    test results, performance metrics, environment information, and trend analysis.
#>

# Import dependent modules
$modulePath = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $modulePath 'modules\TestMetrics.psm1') -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulePath 'modules\TestAnalysis.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Generates comprehensive test execution reports.

.DESCRIPTION
    Creates detailed reports combining test results, performance metrics,
    environment information, and trend analysis.

.PARAMETER TestResult
    The Pester test result object.

.PARAMETER PerformanceData
    Performance metrics data.

.PARAMETER EnvironmentInfo
    Environment information.

.PARAMETER HistoricalData
    Historical test data for trend analysis.

.PARAMETER ReportType
    Type of report to generate.

.OUTPUTS
    Comprehensive test report
#>
function New-ComprehensiveTestReport {
    param(
        $TestResult,
        $PerformanceData,
        $EnvironmentInfo,
        $HistoricalData,
        [ValidateSet('Summary', 'Detailed', 'Executive', 'Technical')]
        [string]$ReportType = 'Summary'
    )

    $report = @{
        GeneratedAt     = Get-Date
        ReportType      = $ReportType
        Environment     = $EnvironmentInfo
        TestResults     = @{}
        Performance     = @{}
        Trends          = @{}
        Recommendations = @()
        QualityMetrics  = @{}
    }

    # Test results summary
    $report.TestResults = @{
        TotalTests      = $TestResult.TotalCount
        PassedTests     = $TestResult.PassedCount
        FailedTests     = $TestResult.FailedCount
        SkippedTests    = $TestResult.SkippedCount
        SuccessRate     = if ($TestResult.TotalCount -gt 0) {
            [Math]::Round(($TestResult.PassedCount / $TestResult.TotalCount) * 100, 2)
        }
        else { 0 }
        Duration        = $TestResult.Time
        FailedTestsList = $TestResult.FailedTests | Select-Object Name, File, ErrorRecord
    }

    # Performance analysis
    if ($PerformanceData) {
        $report.Performance = @{
            TotalDuration    = $PerformanceData.Duration
            MemoryUsage      = @{
                PeakMB    = $PerformanceData.PeakMemoryMB
                AverageMB = $PerformanceData.AverageMemoryMB
            }
            CPUUsage         = $PerformanceData.CPUUsage
            PerformanceGrade = Get-PerformanceGrade -PerformanceData $PerformanceData
        }
    }

    # Trend analysis
    if ($HistoricalData) {
        $report.Trends = Analyze-TestTrends -CurrentResult $TestResult -HistoricalData $HistoricalData
    }

    # Quality metrics
    $report.QualityMetrics = @{
        TestCoverage     = Calculate-TestCoverage -TestResult $TestResult
        StabilityScore   = Calculate-StabilityScore -TestResult $TestResult
        PerformanceScore = Calculate-PerformanceScore -PerformanceData $PerformanceData
        OverallQuality   = 0  # Calculated below
    }

    # Calculate overall quality score
    $qualityComponents = @(
        $report.QualityMetrics.TestCoverage * 0.4,
        $report.QualityMetrics.StabilityScore * 0.4,
        $report.QualityMetrics.PerformanceScore * 0.2
    )
    $report.QualityMetrics.OverallQuality = [Math]::Round(($qualityComponents | Measure-Object -Average).Average, 2)

    # Generate recommendations
    $report.Recommendations = Get-ComprehensiveRecommendations -Report $report

    return $report
}

Export-ModuleMember -Function New-ComprehensiveTestReport

