<#
scripts/lib/Metrics.psm1

.SYNOPSIS
    Historical metrics tracking and trend analysis utilities.

.DESCRIPTION
    Provides functions for saving metrics snapshots, loading historical metrics,
    and analyzing trends over time.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import dependencies
$pathModulePath = Join-Path $PSScriptRoot 'Path.psm1'
$fileSystemModulePath = Join-Path $PSScriptRoot 'FileSystem.psm1'
if (Test-Path $pathModulePath) {
    Import-Module $pathModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if (Test-Path $fileSystemModulePath) {
    Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

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

<#
.SYNOPSIS
    Loads historical metrics from snapshot files.

.DESCRIPTION
    Reads historical metrics snapshots from a directory and returns them as an array.
    Snapshot files should be named with pattern metrics-*.json.

.PARAMETER HistoryPath
    Path to directory containing historical metrics snapshots.

.PARAMETER Limit
    Maximum number of snapshots to load. If not specified, loads all available.

.OUTPUTS
    Array of metrics objects sorted by timestamp (oldest first).

.EXAMPLE
    $historical = Get-HistoricalMetrics -HistoryPath "scripts/data/history"
    Write-Output "Loaded $($historical.Count) historical snapshots"
#>
function Get-HistoricalMetrics {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$HistoryPath,

        [int]$Limit = 0
    )

    if (-not (Test-Path -Path $HistoryPath)) {
        Write-Verbose "History path does not exist: $HistoryPath"
        return @()
    }

    $snapshotFiles = Get-ChildItem -Path $HistoryPath -Filter 'metrics-*.json' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime

    if ($Limit -gt 0) {
        $snapshotFiles = $snapshotFiles | Select-Object -Last $Limit
    }

    $historicalData = [System.Collections.Generic.List[object]]::new()

    foreach ($file in $snapshotFiles) {
        try {
            $data = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $historicalData.Add($data)
        }
        catch {
            Write-Warning "Failed to load historical snapshot $($file.Name): $($_.Exception.Message)"
        }
    }

    return $historicalData.ToArray()
}

<#
.SYNOPSIS
    Saves a snapshot of current metrics for historical tracking.

.DESCRIPTION
    Collects current code and performance metrics and saves them as a timestamped
    snapshot file. This enables historical trend analysis over time.

.PARAMETER OutputPath
    Directory where snapshot will be saved. Defaults to scripts/data/history.

.PARAMETER IncludeCodeMetrics
    If specified, includes code metrics in the snapshot.

.PARAMETER IncludePerformanceMetrics
    If specified, includes performance metrics in the snapshot.

.PARAMETER RepoRoot
    Repository root path. If not specified, will be detected automatically.

.OUTPUTS
    String. Path to the saved snapshot file.

.EXAMPLE
    $snapshotPath = Save-MetricsSnapshot -IncludeCodeMetrics -IncludePerformanceMetrics
    Write-Output "Snapshot saved to: $snapshotPath"
#>
function Save-MetricsSnapshot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$OutputPath = $null,

        [switch]$IncludeCodeMetrics,

        [switch]$IncludePerformanceMetrics,

        [string]$RepoRoot = $null
    )

    # Detect repo root if not provided
    if (-not $RepoRoot) {
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $RepoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
            }
            catch {
                # Fallback: try to detect from current location
                $currentPath = $PWD.Path
                while ($currentPath -and -not (Test-Path -Path (Join-Path $currentPath '.git'))) {
                    $parent = Split-Path -Parent $currentPath
                    if ($parent -eq $currentPath) { break }
                    $currentPath = $parent
                }
                if ($currentPath) {
                    $RepoRoot = $currentPath
                }
                else {
                    throw "Could not determine repository root"
                }
            }
        }
        else {
            # Fallback: try to detect from current location
            $currentPath = $PWD.Path
            while ($currentPath -and -not (Test-Path -Path (Join-Path $currentPath '.git'))) {
                $parent = Split-Path -Parent $currentPath
                if ($parent -eq $currentPath) { break }
                $currentPath = $parent
            }
            if ($currentPath) {
                $RepoRoot = $currentPath
            }
            else {
                throw "Could not determine repository root"
            }
        }
    }

    # Determine output path
    if (-not $OutputPath) {
        $OutputPath = Join-Path $RepoRoot 'scripts' 'data' 'history'
    }

    if (Get-Command Ensure-DirectoryExists -ErrorAction SilentlyContinue) {
        Ensure-DirectoryExists -Path $OutputPath
    }
    else {
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
    }

    # Collect metrics
    $snapshot = [ordered]@{
        Timestamp = [DateTime]::UtcNow.ToString('o')
        Source    = 'PowerShell Profile Codebase'
    }

    if ($IncludeCodeMetrics) {
        $codeMetricsFile = Join-Path $RepoRoot 'scripts' 'data' 'code-metrics.json'
        if (Test-Path -Path $codeMetricsFile) {
            try {
                $snapshot.CodeMetrics = Get-Content -Path $codeMetricsFile -Raw | ConvertFrom-Json
            }
            catch {
                Write-Warning "Failed to load code metrics: $($_.Exception.Message)"
            }
        }
    }

    if ($IncludePerformanceMetrics) {
        $performanceFile = Join-Path $RepoRoot 'scripts' 'data' 'performance-baseline.json'
        if (Test-Path -Path $performanceFile) {
            try {
                $snapshot.PerformanceMetrics = Get-Content -Path $performanceFile -Raw | ConvertFrom-Json
            }
            catch {
                Write-Warning "Failed to load performance metrics: $($_.Exception.Message)"
            }
        }
    }

    # Generate filename with timestamp
    $timestamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
    $filename = "metrics-$timestamp.json"
    $snapshotPath = Join-Path $OutputPath $filename

    # Save snapshot
    try {
        $snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding UTF8
        Write-Verbose "Metrics snapshot saved to: $snapshotPath"
        return $snapshotPath
    }
    catch {
        throw "Failed to save metrics snapshot: $($_.Exception.Message)"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-MetricsTrend',
    'Get-HistoricalMetrics',
    'Save-MetricsSnapshot'
)

