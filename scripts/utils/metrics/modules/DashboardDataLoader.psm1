<#
scripts/utils/metrics/modules/DashboardDataLoader.psm1

.SYNOPSIS
    Dashboard data loading utilities.

.DESCRIPTION
    Provides functions for loading metrics data from JSON files for dashboard generation.
#>

<#
.SYNOPSIS
    Loads current metrics data from JSON files.

.DESCRIPTION
    Loads code metrics, performance metrics, and coverage trends from their respective JSON files.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    Hashtable with CodeMetrics, PerformanceMetrics, and CoverageTrends properties.
#>
function Get-DashboardMetrics {
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $codeMetricsFile = Join-Path $RepoRoot 'scripts' 'data' 'code-metrics.json'
    $performanceBaselineFile = Join-Path $RepoRoot 'scripts' 'data' 'performance-baseline.json'
    $coverageTrendsFile = Join-Path $RepoRoot 'scripts' 'data' 'coverage-trends.json'

    $codeMetrics = $null
    $performanceMetrics = $null
    $coverageTrends = $null

    if (Test-Path -Path $codeMetricsFile) {
        try {
            $codeMetrics = Get-Content -Path $codeMetricsFile -Raw | ConvertFrom-Json
            Write-ScriptMessage -Message "Loaded code metrics" -LogLevel Info
        }
        catch {
            Write-ScriptMessage -Message "Failed to load code metrics: $($_.Exception.Message)" -IsWarning
        }
    }

    if (Test-Path -Path $performanceBaselineFile) {
        try {
            $performanceMetrics = Get-Content -Path $performanceBaselineFile -Raw | ConvertFrom-Json
            Write-ScriptMessage -Message "Loaded performance metrics" -LogLevel Info
        }
        catch {
            Write-ScriptMessage -Message "Failed to load performance metrics: $($_.Exception.Message)" -IsWarning
        }
    }

    if (Test-Path -Path $coverageTrendsFile) {
        try {
            $coverageTrends = Get-Content -Path $coverageTrendsFile -Raw | ConvertFrom-Json
            Write-ScriptMessage -Message "Loaded coverage trends" -LogLevel Info
        }
        catch {
            Write-ScriptMessage -Message "Failed to load coverage trends: $($_.Exception.Message)" -IsWarning
        }
    }

    return @{
        CodeMetrics        = $codeMetrics
        PerformanceMetrics = $performanceMetrics
        CoverageTrends     = $coverageTrends
    }
}

<#
.SYNOPSIS
    Loads historical metrics data from a directory.

.DESCRIPTION
    Loads historical metrics snapshots from JSON files in the specified directory.

.PARAMETER HistoricalDataPath
    Path to directory containing historical metrics snapshots.

.OUTPUTS
    Array of historical metrics objects.
#>
function Get-DashboardHistoricalData {
    param(
        [Parameter(Mandatory)]
        [string]$HistoricalDataPath
    )

    if (-not (Test-Path -Path $HistoricalDataPath)) {
        Write-ScriptMessage -Message "Historical data directory not found: $HistoricalDataPath" -IsWarning
        return @()
    }

    try {
        $historicalFiles = Get-ChildItem -Path $HistoricalDataPath -Filter 'metrics-*.json' | Sort-Object LastWriteTime
        $historicalData = @()

        foreach ($file in $historicalFiles) {
            try {
                $data = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                $historicalData += $data
            }
            catch {
                Write-ScriptMessage -Message "Failed to load historical file $($file.Name): $($_.Exception.Message)" -IsWarning
            }
        }

        Write-ScriptMessage -Message "Loaded $($historicalData.Count) historical snapshots" -LogLevel Info
        return $historicalData
    }
    catch {
        Write-ScriptMessage -Message "Failed to load historical data: $($_.Exception.Message)" -IsWarning
        return @()
    }
}

Export-ModuleMember -Function @(
    'Get-DashboardMetrics',
    'Get-DashboardHistoricalData'
)

