<#
scripts/utils/code-quality/modules/TestRecommendations.psm1

.SYNOPSIS
    Test recommendations utilities.

.DESCRIPTION
    Provides functions for generating recommendations based on test analysis.
#>

<#
.SYNOPSIS
    Generates recommendations based on test analysis.

.DESCRIPTION
    Provides actionable recommendations to improve test quality,
    performance, and reliability.

.PARAMETER Analysis
    The test analysis object.

.OUTPUTS
    Array of recommendation strings
#>
function Get-TestRecommendations {
    param(
        [Parameter(Mandatory)]
        $Analysis
    )

    $recommendations = @()

    # Failure-based recommendations
    if ($Analysis.Summary.FailedTests -gt 0) {
        $recommendations += "Address $($Analysis.Summary.FailedTests) failing test(s)"

        if ($Analysis.FailureAnalysis.MostCommonErrors) {
            $topError = $Analysis.FailureAnalysis.MostCommonErrors[0]
            $recommendations += "Investigate most common error: '$($topError.ErrorMessage)' (affects $($topError.Count) tests)"
        }
    }

    # Performance-based recommendations
    if ($Analysis.PerformanceAnalysis) {
        $perf = $Analysis.PerformanceAnalysis

        if ($perf.SlowestTests -and $perf.SlowestTests.Count -gt 0) {
            $slowest = $perf.SlowestTests[0]
            $recommendations += "Optimize slowest test '$($slowest.Name)' ($($slowest.Duration))"
        }

        if ($perf.PerformanceDistribution.VerySlow -gt 0) {
            $recommendations += "Consider parallel execution or optimization for $($perf.PerformanceDistribution.VerySlow) very slow tests (>10s)"
        }
    }

    # Coverage recommendations
    if ($Analysis.Summary.SuccessRate -lt 90) {
        $recommendations += "Improve test coverage - current success rate: $($Analysis.Summary.SuccessRate)%"
    }

    # General recommendations
    if ($Analysis.Summary.SkippedTests -gt 0) {
        $recommendations += "Review $($Analysis.Summary.SkippedTests) skipped test(s) - ensure they are intentionally skipped"
    }

    return $recommendations
}

Export-ModuleMember -Function Get-TestRecommendations

