<#
scripts/utils/metrics/save-metrics-snapshot.ps1

.SYNOPSIS
    Saves a snapshot of current metrics for historical tracking.

.DESCRIPTION
    Collects current code and performance metrics and saves them as a timestamped
    snapshot file. This enables historical trend analysis over time. Designed to be
    run periodically (e.g., via CI/CD) to build a history of metrics.

.PARAMETER IncludeCodeMetrics
    If specified, includes code metrics in the snapshot. Defaults to true.

.PARAMETER IncludePerformanceMetrics
    If specified, includes performance metrics in the snapshot.

.PARAMETER OutputPath
    Directory where snapshot will be saved. Defaults to scripts/data/history.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\save-metrics-snapshot.ps1

    Saves a snapshot with code metrics only.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\save-metrics-snapshot.ps1 -IncludePerformanceMetrics

    Saves a snapshot with both code and performance metrics.
#>

param(
    [switch]$IncludeCodeMetrics = $true,

    [switch]$IncludePerformanceMetrics,

    [string]$OutputPath = $null
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Saving metrics snapshot..." -LogLevel Info

# Ensure code metrics exist if requested
if ($IncludeCodeMetrics) {
    $codeMetricsFile = Join-Path $repoRoot 'scripts' 'data' 'code-metrics.json'
    if (-not (Test-Path -Path $codeMetricsFile)) {
        Write-ScriptMessage -Message "Code metrics file not found. Collecting metrics..." -LogLevel Info
        try {
            $collectScript = Join-Path $repoRoot 'scripts' 'utils' 'metrics' 'collect-code-metrics.ps1'
            & $collectScript
        }
        catch {
            Write-ScriptMessage -Message "Failed to collect code metrics: $($_.Exception.Message)" -IsWarning
            $IncludeCodeMetrics = $false
        }
    }
}

# Save snapshot
try {
    $snapshotPath = Save-MetricsSnapshot `
        -IncludeCodeMetrics:$IncludeCodeMetrics `
        -IncludePerformanceMetrics:$IncludePerformanceMetrics `
        -OutputPath $OutputPath `
        -RepoRoot $repoRoot
    
    Write-ScriptMessage -Message "Metrics snapshot saved: $snapshotPath" -LogLevel Info
    
    # Display snapshot info
    $snapshot = Read-JsonFile -Path $snapshotPath -ErrorAction SilentlyContinue
    if ($snapshot) {
        Write-ScriptMessage -Message "Snapshot timestamp: $($snapshot.Timestamp)" -LogLevel Info
    }
    
    if ($snapshot.CodeMetrics) {
        Write-ScriptMessage -Message "  Code Metrics: $($snapshot.CodeMetrics.TotalFiles) files, $($snapshot.CodeMetrics.TotalLines) lines" -LogLevel Info
    }
    
    if ($snapshot.PerformanceMetrics) {
        Write-ScriptMessage -Message "  Performance Metrics: Included" -LogLevel Info
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to save metrics snapshot: $($_.Exception.Message)" -ErrorRecord $_
}

Exit-WithCode -ExitCode $EXIT_SUCCESS


