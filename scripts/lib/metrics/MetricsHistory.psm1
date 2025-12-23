<#
scripts/lib/MetricsHistory.psm1

.SYNOPSIS
    Historical metrics loading utilities.

.DESCRIPTION
    Provides functions for loading historical metrics from snapshot files.
#>

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
        return [object[]]::new(0)
    }

    $snapshotFiles = Get-ChildItem -Path $HistoryPath -Filter 'metrics-*.json' -ErrorAction SilentlyContinue
    
    if ($null -eq $snapshotFiles -or $snapshotFiles.Count -eq 0) {
        return [object[]]::new(0)
    }
    
    $snapshotFiles = $snapshotFiles | Sort-Object LastWriteTime

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

    $result = [object[]]$historicalData.ToArray()
    return , $result
}

Export-ModuleMember -Function Get-HistoricalMetrics

