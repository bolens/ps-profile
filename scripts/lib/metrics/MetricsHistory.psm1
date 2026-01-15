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
        [ValidateNotNullOrEmpty()]
        [string]$HistoryPath,

        [int]$Limit = 0
    )

    if (-not (Test-Path -Path $HistoryPath)) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[metrics-history.load] History path does not exist: $HistoryPath"
        }
        return [object[]]::new(0)
    }

    $snapshotFiles = Get-ChildItem -Path $HistoryPath -Filter 'metrics-*.json' -ErrorAction SilentlyContinue
    
    if ($null -eq $snapshotFiles -or $snapshotFiles.Count -eq 0) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "  [metrics-history.load] No snapshot files found in: $HistoryPath" -ForegroundColor DarkGray
        }
        return [object[]]::new(0)
    }
    
    $snapshotFiles = $snapshotFiles | Sort-Object LastWriteTime

    if ($Limit -gt 0) {
        $snapshotFiles = $snapshotFiles | Select-Object -Last $Limit
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [metrics-history.load] Limited to $Limit snapshots from $($snapshotFiles.Count) total files" -ForegroundColor DarkGray
        }
    }

    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Verbose "[metrics-history.load] Processing $($snapshotFiles.Count) snapshot files"
    }

    $historicalData = [System.Collections.Generic.List[object]]::new()

    foreach ($file in $snapshotFiles) {
        try {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [metrics-history.load] Loading snapshot: $($file.Name)" -ForegroundColor DarkGray
            }
            $data = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $historicalData.Add($data)
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [metrics-history.load] Successfully loaded snapshot: $($file.Name)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to load historical snapshot" -OperationName 'metrics-history.load' -Context @{
                    file_name     = $file.Name
                    file_path     = $file.FullName
                    error_message = $_.Exception.Message
                } -Code 'SnapshotLoadFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        Write-Warning "[metrics-history.load] Failed to load historical snapshot $($file.Name): $($_.Exception.Message)"
                    }
                    # Level 3: Log detailed error information
                    if ($debugLevel -ge 3) {
                        Write-Host "  [metrics-history.load] Snapshot load error details - FileName: $($file.Name), FilePath: $($file.FullName), Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                    }
                }
                else {
                    # Always log warnings even if debug is off
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to load historical snapshot" -OperationName 'metrics-history.load' -Context @{
                            # Technical context
                            file_name     = $file.Name
                            file_path     = $file.FullName
                            history_path  = $HistoryPath
                            # Error context
                            error_message = $_.Exception.Message
                            ErrorType     = $_.Exception.GetType().FullName
                            # Operation context
                            limit         = $Limit
                            # Invocation context
                            FunctionName  = 'Get-HistoricalMetrics'
                        } -Code 'SnapshotLoadFailed'
                    }
                    else {
                        Write-Warning "[metrics-history.load] Failed to load historical snapshot $($file.Name): $($_.Exception.Message)"
                    }
                }
            }
        }
    }

    $result = [object[]]$historicalData.ToArray()
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Host "  [metrics-history.load] Successfully loaded $($result.Count) historical snapshots" -ForegroundColor DarkGray
    }
    
    return , $result
}

Export-ModuleMember -Function Get-HistoricalMetrics

