<#
scripts/utils/code-quality/modules/TestMetrics.psm1

.SYNOPSIS
    Test metrics and scoring utilities for the PowerShell profile test runner.

.DESCRIPTION
    Provides functions for calculating performance scores, test coverage,
    stability metrics, and performance grades.
#>

<#
.SYNOPSIS
    Calculates performance grade based on metrics.

.DESCRIPTION
    Assigns a performance grade (A-F) based on duration, memory usage, and CPU usage.

.PARAMETER PerformanceData
    Performance metrics data.

.OUTPUTS
    Performance grade string
#>
function Get-PerformanceGrade {
    param($PerformanceData)

    if (-not $PerformanceData) { return 'N/A' }

    $score = 100

    # Duration scoring (faster is better)
    if ($PerformanceData.Duration.TotalSeconds -gt 300) { $score -= 20 } # >5min
    elseif ($PerformanceData.Duration.TotalSeconds -gt 120) { $score -= 10 } # >2min

    # Memory scoring (lower is better)
    if ($PerformanceData.PeakMemoryMB -gt 1000) { $score -= 20 } # >1GB
    elseif ($PerformanceData.PeakMemoryMB -gt 500) { $score -= 10 } # >500MB

    # CPU scoring (moderate usage is good, very high might indicate issues)
    if ($PerformanceData.CPUUsage -gt 90) { $score -= 15 }
    elseif ($PerformanceData.CPUUsage -gt 70) { $score -= 5 }

    # Convert score to grade
    switch {
        ($score -ge 90) { 'A' }
        ($score -ge 80) { 'B' }
        ($score -ge 70) { 'C' }
        ($score -ge 60) { 'D' }
        default { 'F' }
    }
}

<#
.SYNOPSIS
    Calculates test coverage score.

.DESCRIPTION
    Estimates test coverage based on test results and code metrics.

.PARAMETER TestResult
    The Pester test result object.

.OUTPUTS
    Coverage score (0-100)
#>
function Calculate-TestCoverage {
    param($TestResult)

    if (-not $TestResult -or $TestResult.TotalCount -eq 0) { return 0 }

    # Simple heuristic: more tests = higher coverage
    # In a real implementation, this would integrate with code coverage tools
    $baseScore = [Math]::Min(100, $TestResult.TotalCount * 2)  # Assume 2 tests per 1% coverage

    # Adjust for test quality
    $qualityMultiplier = 1.0
    if ($TestResult.FailedCount -gt 0) {
        $qualityMultiplier -= 0.1  # Reduce for failures
    }

    return [Math]::Round($baseScore * $qualityMultiplier, 2)
}

<#
.SYNOPSIS
    Calculates test stability score.

.DESCRIPTION
    Measures test stability based on failure rates and consistency.

.PARAMETER TestResult
    The Pester test result object.

.OUTPUTS
    Stability score (0-100)
#>
function Calculate-StabilityScore {
    param($TestResult)

    if (-not $TestResult -or $TestResult.TotalCount -eq 0) { return 0 }

    $failureRate = $TestResult.FailedCount / $TestResult.TotalCount
    $stabilityScore = (1 - $failureRate) * 100

    # Bonus for high test count (more tests = more confidence in stability)
    if ($TestResult.TotalCount -gt 50) {
        $stabilityScore += 5
    }

    return [Math]::Round([Math]::Max(0, [Math]::Min(100, $stabilityScore)), 2)
}

<#
.SYNOPSIS
    Calculates performance score.

.DESCRIPTION
    Measures performance quality based on execution metrics.

.PARAMETER PerformanceData
    Performance metrics data.

.OUTPUTS
    Performance score (0-100)
#>
function Calculate-PerformanceScore {
    param($PerformanceData)

    if (-not $PerformanceData) { return 50 }  # Neutral score if no data

    $score = 100

    # Duration penalties
    if ($PerformanceData.Duration.TotalSeconds -gt 600) { $score -= 30 } # >10min
    elseif ($PerformanceData.Duration.TotalSeconds -gt 300) { $score -= 15 } # >5min

    # Memory penalties
    if ($PerformanceData.PeakMemoryMB -gt 2000) { $score -= 25 } # >2GB
    elseif ($PerformanceData.PeakMemoryMB -gt 1000) { $score -= 10 } # >1GB

    return [Math]::Round([Math]::Max(0, $score), 2)
}

Export-ModuleMember -Function @(
    'Get-PerformanceGrade',
    'Calculate-TestCoverage',
    'Calculate-StabilityScore',
    'Calculate-PerformanceScore'
)

