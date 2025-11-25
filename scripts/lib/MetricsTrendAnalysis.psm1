<#
scripts/lib/MetricsTrendAnalysis.psm1

.SYNOPSIS
    Metrics trend analysis utilities.

.DESCRIPTION
    Provides functions for analyzing trends in historical metrics data.
#>

<#
.SYNOPSIS
    Analyzes trends in historical metrics data.

.DESCRIPTION
    Processes historical metrics snapshots to identify trends, changes, and patterns
    over time. Calculates growth rates, averages, and identifies significant changes.

.PARAMETER HistoricalData
    Array of historical metrics objects (from JSON snapshots).
    Expected object properties: Timestamp ([string], ISO 8601 format), CodeMetrics ([PSCustomObject], optional),
    PerformanceMetrics ([PSCustomObject], optional), or direct metric properties.
    Type: [object[]] or [PSCustomObject[]]. Each object should have a Timestamp property and metric data.

.PARAMETER MetricName
    Name of the metric to analyze (e.g., 'TotalFiles', 'TotalLines', 'TotalFunctions').
    Supports nested metrics using dot notation: 'CodeMetrics.TotalFiles', 'PerformanceMetrics.FullStartupMean'.

.PARAMETER Days
    Number of days to analyze. If not specified, analyzes all available data.

.OUTPUTS
    PSCustomObject with trend analysis including growth rate, average change, and trend direction.
    Expected properties: TrendDirection ([string]), GrowthRate ([double]), AverageChange ([double]),
    TotalChange ([double]), FirstValue ([double]), LastValue ([double]), DataPoints ([int]),
    MinValue ([double]), MaxValue ([double]), AverageValue ([double]).

.EXAMPLE
    $historical = Get-HistoricalMetrics -HistoryPath "scripts/data/history"
    $trend = Get-MetricsTrend -HistoricalData $historical -MetricName "TotalFiles"
    Write-Output "Files growth rate: $($trend.GrowthRate)%"
#>
function Get-MetricsTrend {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$HistoricalData,

        [Parameter(Mandatory)]
        [string]$MetricName,

        [int]$Days = 0
    )

    # Validate HistoricalData array contains objects with expected structure
    if ($HistoricalData.Count -gt 0) {
        foreach ($data in $HistoricalData) {
            if ($null -eq $data) {
                Write-Warning "HistoricalData array contains null value. Skipping."
                continue
            }
            # Note: Timestamp is optional, but recommended for proper sorting
            # Metric properties are validated during extraction
        }
    }

    if ($HistoricalData.Count -lt 2) {
        return [PSCustomObject]@{
            TrendDirection = "InsufficientData"
            GrowthRate     = 0
            AverageChange  = 0
            TotalChange    = 0
            DataPoints     = $HistoricalData.Count
            Message        = "Need at least 2 data points for trend analysis"
        }
    }

    # Filter by date if specified
    $filteredData = if ($Days -gt 0) {
        $cutoffDate = [DateTime]::UtcNow.AddDays(-$Days)
        $HistoricalData | Where-Object {
            $timestamp = if ($_.Timestamp) { [DateTime]::Parse($_.Timestamp) } else { [DateTime]::MinValue }
            $timestamp -ge $cutoffDate
        } | Sort-Object { if ($_.Timestamp) { [DateTime]::Parse($_.Timestamp) } else { [DateTime]::MinValue } }
    }
    else {
        $HistoricalData | Sort-Object { if ($_.Timestamp) { [DateTime]::Parse($_.Timestamp) } else { [DateTime]::MinValue } }
    }

    if ($filteredData.Count -lt 2) {
        return [PSCustomObject]@{
            TrendDirection = "InsufficientData"
            GrowthRate     = 0
            AverageChange  = 0
            TotalChange    = 0
            DataPoints     = $filteredData.Count
            Message        = "Insufficient data points after filtering"
        }
    }

    # Extract metric values
    $values = @()
    foreach ($data in $filteredData) {
        $value = $null

        # Navigate through nested structure (CodeMetrics.TotalFiles, PerformanceMetrics.FullStartupMean, etc.)
        if ($MetricName -like "CodeMetrics.*") {
            $metricPath = $MetricName -replace "CodeMetrics\.", ""
            $value = $data.CodeMetrics.$metricPath
        }
        elseif ($MetricName -like "PerformanceMetrics.*") {
            $metricPath = $MetricName -replace "PerformanceMetrics\.", ""
            $value = $data.PerformanceMetrics.$metricPath
        }
        else {
            $value = $data.$MetricName
        }

        if ($null -ne $value -and (($value -is [double]) -or ($value -is [int]) -or ($value -is [long]))) {
            $values += [double]$value
        }
    }

    if ($values.Count -lt 2) {
        return [PSCustomObject]@{
            TrendDirection = "InsufficientData"
            GrowthRate     = 0
            AverageChange  = 0
            TotalChange    = 0
            DataPoints     = $values.Count
            Message        = "Could not extract metric values"
        }
    }

    $firstValue = $values[0]
    $lastValue = $values[$values.Count - 1]
    $totalChange = $lastValue - $firstValue
    $growthRate = if ($firstValue -gt 0) {
        [math]::Round(($totalChange / $firstValue) * 100, 2)
    }
    else {
        0
    }

    # Calculate average change per data point
    $changes = @()
    for ($i = 1; $i -lt $values.Count; $i++) {
        $changes += $values[$i] - $values[$i - 1]
    }
    $averageChange = if ($changes.Count -gt 0) {
        [math]::Round(($changes | Measure-Object -Average).Average, 2)
    }
    else {
        0
    }

    # Determine trend direction
    $trendDirection = if ($growthRate -gt 5) {
        "Increasing"
    }
    elseif ($growthRate -lt -5) {
        "Decreasing"
    }
    else {
        "Stable"
    }

    return [PSCustomObject]@{
        TrendDirection = $trendDirection
        GrowthRate     = $growthRate
        AverageChange  = $averageChange
        TotalChange    = [math]::Round($totalChange, 2)
        FirstValue     = [math]::Round($firstValue, 2)
        LastValue      = [math]::Round($lastValue, 2)
        DataPoints     = $values.Count
        MinValue       = [math]::Round(($values | Measure-Object -Minimum).Minimum, 2)
        MaxValue       = [math]::Round(($values | Measure-Object -Maximum).Maximum, 2)
        AverageValue   = [math]::Round(($values | Measure-Object -Average).Average, 2)
    }
}

Export-ModuleMember -Function Get-MetricsTrend

