<#
scripts/utils/code-quality/modules/TestReporting.psm1

.SYNOPSIS
    Advanced test reporting and analysis utilities.

.DESCRIPTION
    Provides functions for detailed test result analysis, failure analysis,
    performance analysis, trend analysis, and test categorization.
    
    This module defines Get-TestAnalysisReport which uses functions from specialized submodules:
    - TestFailureAnalysis.psm1: Failure analysis
    - TestPerformanceAnalysis.psm1: Performance analysis
    - TestCategorization.psm1: Test categorization
    - TestRecommendations.psm1: Recommendations generation
    - TestTrendAnalysis.psm1: Trend analysis placeholder
    - TestReportFormats.psm1: Report formatting
    - BaselineGeneration.psm1: Baseline generation
    - BaselineComparison.psm1: Baseline comparison
    
    Note: Import submodules directly to use their functions - this module only exports Get-TestAnalysisReport.
#>

# Import specialized submodules
$failureAnalysisModulePath = Join-Path $PSScriptRoot 'TestFailureAnalysis.psm1'
$performanceAnalysisModulePath = Join-Path $PSScriptRoot 'TestPerformanceAnalysis.psm1'
$categorizationModulePath = Join-Path $PSScriptRoot 'TestCategorization.psm1'
$recommendationsModulePath = Join-Path $PSScriptRoot 'TestRecommendations.psm1'
$trendAnalysisModulePath = Join-Path $PSScriptRoot 'TestTrendAnalysis.psm1'

if ($failureAnalysisModulePath -and -not [string]::IsNullOrWhiteSpace($failureAnalysisModulePath) -and (Test-Path -LiteralPath $failureAnalysisModulePath)) {
    Import-Module $failureAnalysisModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if ($performanceAnalysisModulePath -and -not [string]::IsNullOrWhiteSpace($performanceAnalysisModulePath) -and (Test-Path -LiteralPath $performanceAnalysisModulePath)) {
    Import-Module $performanceAnalysisModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if ($categorizationModulePath -and -not [string]::IsNullOrWhiteSpace($categorizationModulePath) -and (Test-Path -LiteralPath $categorizationModulePath)) {
    Import-Module $categorizationModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if ($recommendationsModulePath -and -not [string]::IsNullOrWhiteSpace($recommendationsModulePath) -and (Test-Path -LiteralPath $recommendationsModulePath)) {
    Import-Module $recommendationsModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if ($trendAnalysisModulePath -and -not [string]::IsNullOrWhiteSpace($trendAnalysisModulePath) -and (Test-Path -LiteralPath $trendAnalysisModulePath)) {
    Import-Module $trendAnalysisModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import dependent modules (BaselineManagement.psm1 barrel file - import submodules directly)
$modulePath = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $modulePath 'modules\TestReportFormats.psm1') -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulePath 'modules\BaselineGeneration.psm1') -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulePath 'modules\BaselineComparison.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Analyzes test results and generates detailed insights.

.DESCRIPTION
    Performs comprehensive analysis of test results including failure patterns,
    performance trends, and test categorization.

.PARAMETER TestResult
    The Pester test result object to analyze.

.PARAMETER IncludePerformance
    Include performance analysis in the report.

.PARAMETER IncludeTrends
    Include trend analysis if historical data is available.

.OUTPUTS
    Test analysis report object
#>
function Get-TestAnalysisReport {
    param(
        [Parameter(Mandatory)]
        $TestResult,

        [switch]$IncludePerformance,

        [switch]$IncludeTrends
    )

    $analysis = @{
        Summary             = @{
            TotalTests   = $TestResult.TotalCount
            PassedTests  = $TestResult.PassedCount
            FailedTests  = $TestResult.FailedCount
            SkippedTests = $TestResult.SkippedCount
            SuccessRate  = if ($TestResult.TotalCount -gt 0) {
                [Math]::Round(($TestResult.PassedCount / $TestResult.TotalCount) * 100, 2)
            }
            else { 0 }
            Duration     = $TestResult.Time
        }
        FailureAnalysis     = @()
        PerformanceAnalysis = $null
        TrendAnalysis       = $null
        Recommendations     = @()
    }

    # Analyze failures
    if ($TestResult.FailedCount -gt 0) {
        $analysis.FailureAnalysis = Get-FailureAnalysis -TestResult $TestResult
    }

    # Performance analysis
    if ($IncludePerformance) {
        $analysis.PerformanceAnalysis = Get-PerformanceAnalysis -TestResult $TestResult
    }

    # Trend analysis
    if ($IncludeTrends) {
        $analysis.TrendAnalysis = Get-TrendAnalysis
    }

    # Generate recommendations
    $analysis.Recommendations = Get-TestRecommendations -Analysis $analysis

    return $analysis
}

# Import submodules for use by Get-TestAnalysisReport
# Note: Submodules are imported directly in run-pester.ps1, so this import is for internal use only
# Functions from submodules are NOT re-exported - import submodules directly to use them
# - TestFailureAnalysis.psm1: Get-FailureAnalysis
# - TestPerformanceAnalysis.psm1: Get-PerformanceAnalysis
# - TestCategorization.psm1: Get-TestCategory
# - TestRecommendations.psm1: Get-TestRecommendations
# - TestTrendAnalysis.psm1: Get-TrendAnalysis
# - BaselineGeneration.psm1: New-PerformanceBaseline
# - BaselineComparison.psm1: Compare-PerformanceBaseline, New-PerformanceRegressionReport

# Only export this module's own function (not a barrel file)
Export-ModuleMember -Function 'Get-TestAnalysisReport'
