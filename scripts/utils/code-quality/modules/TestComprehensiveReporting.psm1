<#
scripts/utils/code-quality/modules/TestComprehensiveReporting.psm1

.SYNOPSIS
    Comprehensive test reporting utilities.

.DESCRIPTION
    Provides functions for generating comprehensive test execution reports combining
    test results, performance metrics, environment information, and trend analysis.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe configuration values.
#>

# Import CommonEnums for ReportFormat enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

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
    Type of report to generate. Must be a ReportFormat enum value.

.OUTPUTS
    Comprehensive test report
.EXAMPLE
    New-ComprehensiveTestReport

#>
function New-ComprehensiveTestReport {
    param(
        $TestResult,
        $PerformanceData,
        $EnvironmentInfo,
        $HistoricalData,
        [ReportFormat]$ReportType = [ReportFormat]::Summary
    )

    # Convert enum to string
    $reportTypeString = $ReportType.ToString()

    $report = @{
        GeneratedAt     = Get-Date
        ReportType      = $reportTypeString
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
    $coverageScore = [double](Calculate-TestCoverage -TestResult $TestResult)
    $stabilityScore = [double](Calculate-StabilityScore -TestResult $TestResult)
    $performanceScore = [double](Calculate-PerformanceScore -PerformanceData $PerformanceData)

    $report.QualityMetrics = @{
        TestCoverage     = $coverageScore
        StabilityScore   = $stabilityScore
        PerformanceScore = $performanceScore
        OverallQuality   = [Math]::Round(($coverageScore * 0.4) + ($stabilityScore * 0.4) + ($performanceScore * 0.2), 2)
    }

    # Generate recommendations
    $report.Recommendations = Get-ComprehensiveRecommendations -Report $report

    return $report
}

Export-ModuleMember -Function New-ComprehensiveTestReport

