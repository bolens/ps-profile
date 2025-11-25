<#
scripts/utils/code-quality/modules/TestPerformanceAnalysis.psm1

.SYNOPSIS
    Test performance analysis utilities.

.DESCRIPTION
    Provides functions for analyzing test performance characteristics.
#>

<#
.SYNOPSIS
    Analyzes test performance characteristics.

.DESCRIPTION
    Examines test execution times, identifies slow tests,
    and provides performance insights.

.PARAMETER TestResult
    The Pester test result object.

.OUTPUTS
    Performance analysis object
#>
function Get-PerformanceAnalysis {
    param(
        [Parameter(Mandatory)]
        $TestResult
    )

    $analysis = @{
        SlowestTests            = @()
        FastestTests            = @()
        AverageDuration         = $null
        TotalDuration           = $TestResult.Time
        PerformanceDistribution = @{
            Fast     = 0    # < 100ms
            Medium   = 0  # 100ms - 1s
            Slow     = 0    # 1s - 10s
            VerySlow = 0 # > 10s
        }
    }

    if ($TestResult.PassedTests) {
        $durations = $TestResult.PassedTests |
        Where-Object { $_.Duration } |
        Select-Object -ExpandProperty Duration

        if ($durations) {
            $analysis.AverageDuration = [TimeSpan]::FromTicks(($durations | Select-Object -ExpandProperty Ticks | Measure-Object -Average).Average)

            # Categorize tests by duration
            foreach ($duration in $durations) {
                $seconds = $duration.TotalSeconds
                if ($seconds -lt 0.1) {
                    $analysis.PerformanceDistribution.Fast++
                }
                elseif ($seconds -lt 1) {
                    $analysis.PerformanceDistribution.Medium++
                }
                elseif ($seconds -lt 10) {
                    $analysis.PerformanceDistribution.Slow++
                }
                else {
                    $analysis.PerformanceDistribution.VerySlow++
                }
            }

            # Get slowest and fastest tests
            $analysis.SlowestTests = $TestResult.PassedTests |
            Where-Object { $_.Duration } |
            Sort-Object { $_.Duration } -Descending |
            Select-Object -First 5 |
            Select-Object Name, Duration, File

            $analysis.FastestTests = $TestResult.PassedTests |
            Where-Object { $_.Duration } |
            Sort-Object { $_.Duration } |
            Select-Object -First 5 |
            Select-Object Name, Duration, File
        }
    }

    return $analysis
}

Export-ModuleMember -Function Get-PerformanceAnalysis

