<#
scripts/lib/PerformanceAggregation.psm1

.SYNOPSIS
    Performance metrics aggregation utilities.

.DESCRIPTION
    Provides functions for aggregating and reporting performance metrics from multiple operations.
#>

<#
.SYNOPSIS
    Aggregates and reports performance metrics from multiple operations.

.DESCRIPTION
    Collects metrics from multiple Measure-Operation calls and provides
    aggregated statistics including totals, averages, min/max, and percentiles.

.PARAMETER Metrics
    Array of metrics objects from Measure-Operation calls.
    Expected object properties: DurationMs ([double]), Success ([bool]).
    Each object should be a PSCustomObject returned by Measure-Operation.
    Type: [object[]] or [PSCustomObject[]].

.PARAMETER OperationName
    Optional name for the aggregated operation set.

.OUTPUTS
    PSCustomObject with aggregated statistics.

.EXAMPLE
    $metrics1 = Measure-Operation -ScriptBlock { Get-Process } -OperationName "GetProcess1"
    $metrics2 = Measure-Operation -ScriptBlock { Get-Process } -OperationName "GetProcess2"
    $aggregated = Get-AggregatedMetrics -Metrics @($metrics1, $metrics2) -OperationName "GetProcess"
    Write-Output "Average duration: $($aggregated.AverageDurationMs)ms"
#>
function Get-AggregatedMetrics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [object[]]$Metrics,

        [string]$OperationName = "Operations"
    )

    # Validate Metrics array contains objects with expected properties
    $validatedMetrics = [System.Collections.Generic.List[object]]::new()

    foreach ($metric in $Metrics) {
        if ($null -eq $metric) {
            Write-Warning "Metrics array contains null value. Skipping."
            continue
        }

        $hasDuration = $false

        if ($metric -is [System.Collections.IDictionary]) {
            $hasDuration = $metric.Contains('DurationMs')
        }
        else {
            $prop = $metric.PSObject.Properties['DurationMs']
            $hasDuration = $null -ne $prop
        }

        if (-not $hasDuration) {
            Write-Warning "Metric object missing DurationMs property. Skipping."
            continue
        }

        $validatedMetrics.Add($metric)
    }

    if ($validatedMetrics.Count -eq 0) {
        return [PSCustomObject]@{
            OperationName     = $OperationName
            Count             = 0
            TotalDurationMs   = 0
            AverageDurationMs = 0
            MinDurationMs     = 0
            MaxDurationMs     = 0
            SuccessCount      = 0
            FailureCount      = 0
            SuccessRate       = 0
        }
    }

    # Extract duration values (supports both dictionary and object formats)
    $durations = foreach ($metric in $validatedMetrics) {
        if ($metric -is [System.Collections.IDictionary]) {
            $metric['DurationMs']
        }
        else {
            $metric.DurationMs
        }
    }

    # Count successes and failures
    $successCount = 0
    $failureCount = 0

    foreach ($metric in $validatedMetrics) {
        # Extract Success property (may be missing, which is treated as unknown)
        $successValue = if ($metric -is [System.Collections.IDictionary]) {
            $metric['Success']
        }
        else {
            $prop = $metric.PSObject.Properties['Success']
            if ($null -ne $prop) { $prop.Value } else { $null }
        }

        if ($successValue -eq $true) {
            $successCount++
        }
        elseif ($successValue -eq $false) {
            $failureCount++
        }
    }

    # Filter and sort durations for percentile calculations
    $durationList = @()
    foreach ($value in $durations) {
        if ($null -ne $value -and ($value -is [double] -or $value -is [int] -or $value -is [long])) {
            $durationList += [double]$value
        }
    }
    $sortedDurations = $durationList | Sort-Object
    $count = $sortedDurations.Count

    return [PSCustomObject]@{
        OperationName     = $OperationName
        Count             = $validatedMetrics.Count
        TotalDurationMs   = if ($durationList.Count -gt 0) { [math]::Round(($durationList | Measure-Object -Sum).Sum, 2) } else { 0 }
        AverageDurationMs = if ($count -gt 0) { [math]::Round(($durationList | Measure-Object -Average).Average, 2) } else { 0 }
        MinDurationMs     = if ($count -gt 0) { [math]::Round(($sortedDurations | Measure-Object -Minimum).Minimum, 2) } else { 0 }
        MaxDurationMs     = if ($count -gt 0) { [math]::Round(($sortedDurations | Measure-Object -Maximum).Maximum, 2) } else { 0 }
        MedianDurationMs  = if ($count -gt 0) {
            # Calculate median: average of two middle values for even count, middle value for odd count
            $medianIndex = [math]::Floor($count / 2)
            if ($count % 2 -eq 0) {
                [math]::Round(($sortedDurations[$medianIndex - 1] + $sortedDurations[$medianIndex]) / 2, 2)
            }
            else {
                [math]::Round($sortedDurations[$medianIndex], 2)
            }
        }
        else { 0 }
        # Percentile calculations (P50 = median, P95 = 95th percentile, P99 = 99th percentile)
        P50DurationMs     = if ($count -gt 0) { [math]::Round($sortedDurations[[math]::Floor($count * 0.5)], 2) } else { 0 }
        P95DurationMs     = if ($count -gt 0) { [math]::Round($sortedDurations[[math]::Floor($count * 0.95)], 2) } else { 0 }
        P99DurationMs     = if ($count -gt 0) { [math]::Round($sortedDurations[[math]::Floor($count * 0.99)], 2) } else { 0 }
        SuccessCount      = $successCount
        FailureCount      = $failureCount
        SuccessRate       = if ($Metrics.Count -gt 0) { [math]::Round(($successCount / $Metrics.Count) * 100, 2) } else { 0 }
    }
}

Export-ModuleMember -Function Get-AggregatedMetrics

