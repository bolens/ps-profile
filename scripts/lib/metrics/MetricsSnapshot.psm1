<#
scripts/lib/MetricsSnapshot.psm1

.SYNOPSIS
    Metrics snapshot saving utilities.

.DESCRIPTION
    Provides functions for saving metrics snapshots for historical tracking.
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import dependencies (Path.psm1 barrel file - import submodule directly)
$pathResolutionModulePath = Join-Path $PSScriptRoot 'PathResolution.psm1'
$fileSystemModulePath = Join-Path $PSScriptRoot 'FileSystem.psm1'
$jsonUtilitiesModulePath = Join-Path $PSScriptRoot 'JsonUtilities.psm1'

if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $jsonUtilitiesModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($pathResolutionModulePath -and -not [string]::IsNullOrWhiteSpace($pathResolutionModulePath) -and (Test-Path -LiteralPath $pathResolutionModulePath)) {
        Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    if ($fileSystemModulePath -and -not [string]::IsNullOrWhiteSpace($fileSystemModulePath) -and (Test-Path -LiteralPath $fileSystemModulePath)) {
        Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    if ($jsonUtilitiesModulePath -and -not [string]::IsNullOrWhiteSpace($jsonUtilitiesModulePath) -and (Test-Path -LiteralPath $jsonUtilitiesModulePath)) {
        Import-Module $jsonUtilitiesModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
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
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to load code metrics" -OperationName 'metrics-snapshot.save' -Context @{
                        code_metrics_file = $codeMetricsFile
                        error_message     = $_.Exception.Message
                    } -Code 'CodeMetricsLoadFailed'
                }
                else {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            Write-Warning "[metrics-snapshot.save] Failed to load code metrics: $($_.Exception.Message)"
                        }
                        # Level 3: Log detailed error information
                        if ($debugLevel -ge 3) {
                            Write-Host "  [metrics-snapshot.save] Code metrics load error details - CodeMetricsFile: $codeMetricsFile, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        # Always log warnings even if debug is off
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Failed to load code metrics" -OperationName 'metrics-snapshot.save' -Context @{
                                # Technical context
                                code_metrics_file    = $codeMetricsFile
                                repo_root            = $RepoRoot
                                output_path          = $OutputPath
                                # Error context
                                error_message        = $_.Exception.Message
                                ErrorType            = $_.Exception.GetType().FullName
                                # Operation context
                                include_code_metrics = $IncludeCodeMetrics.IsPresent
                                # Invocation context
                                FunctionName         = 'Save-MetricsSnapshot'
                            } -Code 'CodeMetricsLoadFailed'
                        }
                        else {
                            Write-Warning "[metrics-snapshot.save] Failed to load code metrics: $($_.Exception.Message)"
                        }
                    }
                }
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
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to load performance metrics" -OperationName 'metrics-snapshot.save' -Context @{
                        performance_file = $performanceFile
                        error_message    = $_.Exception.Message
                    } -Code 'PerformanceMetricsLoadFailed'
                }
                else {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                        Write-Warning "[metrics-snapshot.save] Failed to load performance metrics: $($_.Exception.Message)"
                    }
                }
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
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[metrics-snapshot.save] Metrics snapshot saved to: $snapshotPath"
        }
        
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            $snapshotInfo = "Timestamp=$($snapshot.Timestamp)"
            if ($snapshot.ContainsKey('CodeMetrics')) { $snapshotInfo += ", CodeMetrics=included" }
            if ($snapshot.ContainsKey('PerformanceMetrics')) { $snapshotInfo += ", PerformanceMetrics=included" }
            Write-Verbose "[metrics-snapshot.save] Snapshot details: $snapshotInfo"
        }
        
        return $snapshotPath
    }
    catch {
        $errorMsg = "Failed to save metrics snapshot: $($_.Exception.Message)"
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics-snapshot.save' -Context @{
                snapshot_path = $snapshotPath
                error_message = $errorMsg
            }
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics-snapshot.save' -Context @{
                                # Technical context
                                snapshot_path               = $snapshotPath
                                output_path                 = $OutputPath
                                repo_root                   = $RepoRoot
                                # Error context
                                error_message               = $errorMsg
                                ErrorType                   = $_.Exception.GetType().FullName
                                # Operation context
                                include_code_metrics        = $IncludeCodeMetrics.IsPresent
                                include_performance_metrics = $IncludePerformanceMetrics.IsPresent
                                # Invocation context
                                FunctionName                = 'Save-MetricsSnapshot'
                            }
                        }
                        else {
                            Write-Error "[metrics-snapshot.save] $errorMsg" -ErrorAction Continue
                        }
                    }
                    # Level 3: Log detailed error information
                    if ($debugLevel -ge 3) {
                        Write-Host "  [metrics-snapshot.save] Save error details - SnapshotPath: $snapshotPath, OutputPath: $OutputPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                    }
                }
                else {
                    # Always log critical errors even if debug is off
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'metrics-snapshot.save' -Context @{
                            snapshot_path               = $snapshotPath
                            output_path                 = $OutputPath
                            repo_root                   = $RepoRoot
                            error_message               = $errorMsg
                            ErrorType                   = $_.Exception.GetType().FullName
                            include_code_metrics        = $IncludeCodeMetrics.IsPresent
                            include_performance_metrics = $IncludePerformanceMetrics.IsPresent
                            FunctionName                = 'Save-MetricsSnapshot'
                        }
                    }
                    else {
                        Write-Error "[metrics-snapshot.save] $errorMsg" -ErrorAction Continue
                    }
                }
            }
        }
        throw $errorMsg
    }
}

Export-ModuleMember -Function Save-MetricsSnapshot

