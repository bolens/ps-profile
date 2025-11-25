<#
scripts/lib/MetricsSnapshot.psm1

.SYNOPSIS
    Metrics snapshot saving utilities.

.DESCRIPTION
    Provides functions for saving metrics snapshots for historical tracking.
#>

# Import dependencies (Path.psm1 barrel file - import submodule directly)
$pathResolutionModulePath = Join-Path $PSScriptRoot 'PathResolution.psm1'
$fileSystemModulePath = Join-Path $PSScriptRoot 'FileSystem.psm1'
$jsonUtilitiesModulePath = Join-Path $PSScriptRoot 'JsonUtilities.psm1'
if (Test-Path $pathResolutionModulePath) {
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if (Test-Path $fileSystemModulePath) {
    Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if (Test-Path $jsonUtilitiesModulePath) {
    Import-Module $jsonUtilitiesModulePath -DisableNameChecking -ErrorAction SilentlyContinue
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
                if (Get-Command Read-JsonFile -ErrorAction SilentlyContinue) {
                    $snapshot.CodeMetrics = Read-JsonFile -Path $codeMetricsFile -ErrorAction SilentlyContinue
                }
                else {
                    $snapshot.CodeMetrics = Get-Content -Path $codeMetricsFile -Raw | ConvertFrom-Json
                }
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

Export-ModuleMember -Function Save-MetricsSnapshot

