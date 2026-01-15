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
        [AllowNull()]
        [object[]]$HistoricalData,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$MetricName,

        [int]$Days = 0
    )

    # Validate HistoricalData array contains objects with expected structure
    if ($HistoricalData.Count -gt 0) {
        foreach ($data in $HistoricalData) {
            if ($null -eq $data) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "HistoricalData array contains null value" -OperationName 'metrics-trend-analysis.analyze' -Context @{
                        data_count = $HistoricalData.Count
                    } -Code 'NullDataValue'
                }
                else {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 2) {
                            Write-Warning "[metrics-trend-analysis.analyze] HistoricalData array contains null value. Skipping."
                        }
                        # Level 3: Log detailed null value information
                        if ($debugLevel -ge 3) {
                            Write-Host "  [metrics-trend-analysis.analyze] Null data value details - DataCount: $($HistoricalData.Count), MetricName: $MetricName, Index: $($HistoricalData.IndexOf($data))" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        # Always log warnings even if debug is off
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "HistoricalData array contains null value" -OperationName 'metrics-trend-analysis.analyze' -Context @{
                                # Technical context
                                data_count = $HistoricalData.Count
                                metric_name = $MetricName
                                # Invocation context
                                FunctionName = 'Get-MetricsTrend'
                            } -Code 'NullDataValue'
                        }
                        else {
                            Write-Warning "[metrics-trend-analysis.analyze] HistoricalData array contains null value. Skipping."
                        }
                    }
                }
                continue
            }
            # Note: Timestamp is optional, but recommended for proper sorting
            # Metric properties are validated during extraction
        }
    }

    if ($HistoricalData.Count -lt 2) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Insufficient data for trend analysis" -OperationName 'metrics-trend-analysis.analyze' -Context @{
                data_points = $HistoricalData.Count
                metric_name = $MetricName
            } -Code 'InsufficientData'
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    Write-Warning "[metrics-trend-analysis.analyze] Need at least 2 data points for trend analysis. Found: $($HistoricalData.Count)"
                }
                # Level 3: Log detailed insufficient data information
                if ($debugLevel -ge 3) {
                    Write-Verbose "[metrics-trend-analysis.analyze] Insufficient data details - DataPoints: $($HistoricalData.Count), MetricName: $MetricName, Days: $Days"
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Insufficient data for trend analysis" -OperationName 'metrics-trend-analysis.analyze' -Context @{
                        # Technical context
                        data_points = $HistoricalData.Count
                        metric_name = $MetricName
                        # Operation context
                        days = $Days
                        # Invocation context
                        FunctionName = 'Get-MetricsTrend'
                    } -Code 'InsufficientData'
                }
                else {
                    Write-Warning "[metrics-trend-analysis.analyze] Need at least 2 data points for trend analysis. Found: $($HistoricalData.Count)"
                }
            }
        }
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
    # Optimized: Use foreach loop instead of Where-Object
    $filteredData = if ($Days -gt 0) {
        $cutoffDate = [DateTime]::UtcNow.AddDays(-$Days)
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [metrics-trend-analysis.analyze] Filtering data to last $Days days (cutoff: $cutoffDate)" -ForegroundColor DarkGray
        }
        $filtered = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $HistoricalData) {
            $timestamp = if ($item.Timestamp) { [DateTime]::Parse($item.Timestamp) } else { [DateTime]::MinValue }
            if ($timestamp -ge $cutoffDate) {
                $filtered.Add($item)
            }
        }
        $filtered | Sort-Object { if ($_.Timestamp) { [DateTime]::Parse($_.Timestamp) } else { [DateTime]::MinValue } }
    }
    else {
        $HistoricalData | Sort-Object { if ($_.Timestamp) { [DateTime]::Parse($_.Timestamp) } else { [DateTime]::MinValue } }
    }
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Verbose "[metrics-trend-analysis.analyze] Analyzing trend for metric '$MetricName' with $($filteredData.Count) data points"
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
            # Optimized: Use List.Add instead of +=
            $values.Add([double]$value)
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
    # Optimized: Use List for better performance with Add() instead of +=
    $changes = [System.Collections.Generic.List[double]]::new()
    for ($i = 1; $i -lt $values.Count; $i++) {
        $changes.Add($values[$i] - $values[$i - 1])
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
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [metrics-trend-analysis.analyze] Trend calculation complete: Direction=$trendDirection, GrowthRate=$growthRate%, AverageChange=$averageChange" -ForegroundColor DarkGray
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

