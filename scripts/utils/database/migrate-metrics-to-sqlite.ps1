<#
scripts/utils/database/migrate-metrics-to-sqlite.ps1

.SYNOPSIS
    Migrates existing performance metrics from JSON/CSV files to SQLite database.

.DESCRIPTION
    Reads performance metrics from existing JSON and CSV files and imports them
    into the SQLite performance metrics database. Useful for migrating historical data.

.PARAMETER BaselineFile
    Path to performance-baseline.json file to import.

.PARAMETER BenchmarkFile
    Path to startup-benchmark.csv file to import.

.PARAMETER MetricsHistoryPath
    Path to directory containing metrics-*.json snapshot files.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\database\migrate-metrics-to-sqlite.ps1 -BaselineFile scripts\data\performance-baseline.json

    Imports baseline performance data into SQLite database.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\database\migrate-metrics-to-sqlite.ps1 -BenchmarkFile scripts\data\startup-benchmark.csv

    Imports benchmark CSV data into SQLite database.
#>

param(
    [string]$BaselineFile,
    
    [string]$BenchmarkFile,
    
    [string]$MetricsHistoryPath
)

# Import shared utilities
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking

# Import Performance Metrics Database
$perfMetricsModule = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'database' 'PerformanceMetricsDatabase.psm1'
if (-not (Test-Path -LiteralPath $perfMetricsModule)) {
    $errorMsg = "Performance Metrics Database module not found: $perfMetricsModule"
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.IO.FileNotFoundException]::new($errorMsg),
            'ModuleNotFound',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $perfMetricsModule
        )
        Write-StructuredError -ErrorRecord $errorRecord -OperationName 'metrics.migration.setup' -Context @{
            module_path = $perfMetricsModule
        }
    }
    else {
        Write-Error $errorMsg
    }
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
}

Import-Module $perfMetricsModule -DisableNameChecking -ErrorAction Stop

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[database.migrate-metrics] Starting metrics migration to SQLite"
    Write-Verbose "[database.migrate-metrics] Baseline file: $BaselineFile, Benchmark file: $BenchmarkFile, Metrics history path: $MetricsHistoryPath"
}

Write-ScriptMessage -Message "Migrating performance metrics to SQLite database..." -LogLevel Info

$importedCount = 0
$migrationStartTime = Get-Date

# Import baseline file
if ($BaselineFile) {
    if (-not [System.IO.Path]::IsPathRooted($BaselineFile)) {
        $BaselineFile = Join-Path $repoRoot $BaselineFile
    }
    
    if (Test-Path -LiteralPath $BaselineFile) {
        Write-ScriptMessage -Message "Importing baseline file: $BaselineFile" -LogLevel Info
        try {
            $baseline = Read-JsonFile -Path $BaselineFile -ErrorAction Stop
            
            # Import full startup time
            if ($baseline.FullStartupMean) {
                try {
                    $timestamp = if ($baseline.Timestamp) {
                        [DateTime]::Parse($baseline.Timestamp)
                    }
                    else {
                        (Get-Item -LiteralPath $BaselineFile).LastWriteTime
                    }
                    
                    Add-PerformanceMetric -MetricType 'startup' -MetricName 'full_startup_mean' -Value $baseline.FullStartupMean -Unit 'ms' -Environment 'local' -Metadata @{
                        Source = 'baseline'
                        File   = $BaselineFile
                    } -ErrorAction Stop
                    $importedCount++
                }
                catch {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to import full startup time metric" -OperationName 'metrics.migration.import-baseline' -Context @{
                            baseline_file = $BaselineFile
                            metric_name = 'full_startup_mean'
                        } -Code 'MetricImportFailed'
                    }
                    else {
                        Write-ScriptMessage -Message "Failed to import full startup time metric: $($_.Exception.Message)" -IsWarning
                    }
                }
            }
            
            # Import fragment timings
            if ($baseline.Fragments) {
                foreach ($frag in $baseline.Fragments) {
                    if ($frag.MeanMs) {
                        try {
                            Add-PerformanceMetric -MetricType 'startup' -MetricName "fragment_$($frag.Fragment)" -Value $frag.MeanMs -Unit 'ms' -Environment 'local' -Metadata @{
                                Source   = 'baseline'
                                Fragment = $frag.Fragment
                            } -ErrorAction Stop
                            $importedCount++
                        }
                        catch {
                            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                Write-StructuredWarning -Message "Failed to import fragment metric" -OperationName 'metrics.migration.import-baseline' -Context @{
                                    baseline_file = $BaselineFile
                                    fragment = $frag.Fragment
                                    metric_name = "fragment_$($frag.Fragment)"
                                } -Code 'MetricImportFailed'
                            }
                            else {
                                Write-ScriptMessage -Message "Failed to import fragment metric for '$($frag.Fragment)': $($_.Exception.Message)" -IsWarning
                            }
                        }
                    }
                }
            }
            
            $baselineDuration = ((Get-Date) - $baselineStartTime).TotalMilliseconds
            
            # Level 2: Baseline import timing
            if ($debugLevel -ge 2) {
                Write-Verbose "[database.migrate-metrics] Baseline file imported in ${baselineDuration}ms - Metrics: $importedCount"
            }
            
            Write-ScriptMessage -Message "Imported $importedCount metrics from baseline file" -LogLevel Info
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.migration.import-baseline' -Context @{
                    baseline_file = $BaselineFile
                }
            }
            else {
                Write-ScriptMessage -Message "Failed to import baseline file: $($_.Exception.Message)" -IsWarning
            }
        }
    }
    else {
        Write-ScriptMessage -Message "Baseline file not found: $BaselineFile" -IsWarning
    }
}

# Import benchmark CSV
if ($BenchmarkFile) {
    # Level 1: Benchmark CSV import start
    if ($debugLevel -ge 1) {
        Write-Verbose "[database.migrate-metrics] Importing benchmark CSV: $BenchmarkFile"
    }
    
    if (-not [System.IO.Path]::IsPathRooted($BenchmarkFile)) {
        $BenchmarkFile = Join-Path $repoRoot $BenchmarkFile
    }
    
    if (Test-Path -LiteralPath $BenchmarkFile) {
        Write-ScriptMessage -Message "Importing benchmark CSV: $BenchmarkFile" -LogLevel Info
        $benchmarkStartTime = Get-Date
        try {
            $benchmarks = Import-Csv -Path $BenchmarkFile -ErrorAction Stop
            $csvImportedCount = 0
            $csvFailedCount = 0
            
            foreach ($benchmark in $benchmarks) {
                if ($benchmark.MeanMs) {
                    try {
                        $meanMs = [double]$benchmark.MeanMs
                        $fragment = $benchmark.Fragment
                        
                        Add-PerformanceMetric -MetricType 'startup' -MetricName "fragment_$fragment" -Value $meanMs -Unit 'ms' -Environment 'local' -Metadata @{
                            Source   = 'benchmark_csv'
                            Fragment = $fragment
                            MedianMs = if ($benchmark.MedianMs) { [double]$benchmark.MedianMs } else { $null }
                        } -ErrorAction Stop
                        $importedCount++
                        $csvImportedCount++
                    }
                    catch {
                        $csvFailedCount++
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Failed to import benchmark metric" -OperationName 'metrics.migration.import-benchmark' -Context @{
                                benchmark_file = $BenchmarkFile
                                fragment = $fragment
                                metric_name = "fragment_$fragment"
                            } -Code 'MetricImportFailed'
                        }
                        else {
                            Write-ScriptMessage -Message "Failed to import benchmark metric for fragment '$fragment': $($_.Exception.Message)" -IsWarning
                        }
                    }
                }
            }
            
            Write-ScriptMessage -Message "Imported $csvImportedCount metrics from benchmark CSV" -LogLevel Info
            if ($csvFailedCount -gt 0) {
                Write-ScriptMessage -Message "Failed to import $csvFailedCount metrics from benchmark CSV" -IsWarning
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.migration.import-benchmark' -Context @{
                    benchmark_file = $BenchmarkFile
                }
            }
            else {
                Write-ScriptMessage -Message "Failed to import benchmark CSV: $($_.Exception.Message)" -IsWarning
            }
        }
    }
    else {
        Write-ScriptMessage -Message "Benchmark file not found: $BenchmarkFile" -IsWarning
    }
}

# Import metrics history snapshots
if ($MetricsHistoryPath) {
    # Level 1: Metrics history import start
    if ($debugLevel -ge 1) {
        Write-Verbose "[database.migrate-metrics] Importing metrics history from: $MetricsHistoryPath"
    }
    
    if (-not [System.IO.Path]::IsPathRooted($MetricsHistoryPath)) {
        $MetricsHistoryPath = Join-Path $repoRoot $MetricsHistoryPath
    }
    
    if (Test-Path -LiteralPath $MetricsHistoryPath -PathType Container) {
        Write-ScriptMessage -Message "Importing metrics history from: $MetricsHistoryPath" -LogLevel Info
        $historyStartTime = Get-Date
        try {
            $snapshotFiles = Get-ChildItem -Path $MetricsHistoryPath -Filter 'metrics-*.json' -ErrorAction SilentlyContinue
            
            # Level 2: Snapshot file discovery
            if ($debugLevel -ge 2) {
                Write-Verbose "[database.migrate-metrics] Found $($snapshotFiles.Count) snapshot file(s)"
            }
            
            foreach ($file in $snapshotFiles) {
                try {
                    $snapshot = Read-JsonFile -Path $file.FullName -ErrorAction Stop
                    $timestamp = $file.LastWriteTime
                    
                    # Import code metrics if available
                    if ($snapshot.CodeMetrics) {
                        $cm = $snapshot.CodeMetrics
                        if ($cm.TotalLines) {
                            try {
                                Add-PerformanceMetric -MetricType 'code_metrics' -MetricName 'total_lines' -Value $cm.TotalLines -Unit 'count' -Environment 'local' -Metadata @{
                                    Source = 'metrics_snapshot'
                                    File   = $file.Name
                                } -ErrorAction Stop
                                $importedCount++
                            }
                            catch {
                                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                    Write-StructuredWarning -Message "Failed to import total_lines metric from snapshot" -OperationName 'metrics.migration.import-snapshot' -Context @{
                                        snapshot_file = $file.Name
                                        metric_name = 'total_lines'
                                    } -Code 'MetricImportFailed'
                                }
                                else {
                                    Write-ScriptMessage -Message "Failed to import total_lines metric from snapshot $($file.Name): $($_.Exception.Message)" -IsWarning
                                }
                            }
                        }
                        if ($cm.TotalFunctions) {
                            try {
                                Add-PerformanceMetric -MetricType 'code_metrics' -MetricName 'total_functions' -Value $cm.TotalFunctions -Unit 'count' -Environment 'local' -Metadata @{
                                    Source = 'metrics_snapshot'
                                    File   = $file.Name
                                } -ErrorAction Stop
                                $importedCount++
                            }
                            catch {
                                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                    Write-StructuredWarning -Message "Failed to import total_functions metric from snapshot" -OperationName 'metrics.migration.import-snapshot' -Context @{
                                        snapshot_file = $file.Name
                                        metric_name = 'total_functions'
                                    } -Code 'MetricImportFailed'
                                }
                                else {
                                    Write-ScriptMessage -Message "Failed to import total_functions metric from snapshot $($file.Name): $($_.Exception.Message)" -IsWarning
                                }
                            }
                        }
                    }
                    
                    # Import performance metrics if available
                    if ($snapshot.PerformanceMetrics) {
                        $pm = $snapshot.PerformanceMetrics
                        if ($pm.Baseline) {
                            if ($pm.Baseline.Performance) {
                                $perf = $pm.Baseline.Performance
                                if ($perf.Duration) {
                                    try {
                                        Add-PerformanceMetric -MetricType 'test' -MetricName 'baseline_duration' -Value $perf.Duration -Unit 'ms' -Environment 'local' -Metadata @{
                                            Source = 'metrics_snapshot'
                                            File   = $file.Name
                                        } -ErrorAction Stop
                                        $importedCount++
                                    }
                                    catch {
                                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                            Write-StructuredWarning -Message "Failed to import baseline_duration metric from snapshot" -OperationName 'metrics.migration.import-snapshot' -Context @{
                                                snapshot_file = $file.Name
                                                metric_name = 'baseline_duration'
                                            } -Code 'MetricImportFailed'
                                        }
                                        else {
                                            Write-ScriptMessage -Message "Failed to import baseline_duration metric from snapshot $($file.Name): $($_.Exception.Message)" -IsWarning
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                catch {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.migration.import-snapshot' -Context @{
                            snapshot_file = $file.Name
                        }
                    }
                    else {
                        Write-ScriptMessage -Message "Failed to import snapshot $($file.Name): $($_.Exception.Message)" -IsWarning
                    }
                }
            }
            
            $historyDuration = ((Get-Date) - $historyStartTime).TotalMilliseconds
            
            # Level 2: Metrics history import timing
            if ($debugLevel -ge 2) {
                Write-Verbose "[database.migrate-metrics] Metrics history imported in ${historyDuration}ms - Snapshots: $($snapshotFiles.Count)"
            }
            
            Write-ScriptMessage -Message "Imported metrics from $($snapshotFiles.Count) snapshot files" -LogLevel Info
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.migration.import-history' -Context @{
                    metrics_history_path = $MetricsHistoryPath
                }
            }
            else {
                Write-ScriptMessage -Message "Failed to import metrics history: $($_.Exception.Message)" -IsWarning
            }
        }
    }
    else {
        Write-ScriptMessage -Message "Metrics history path not found: $MetricsHistoryPath" -IsWarning
    }
}

$migrationDuration = ((Get-Date) - $migrationStartTime).TotalMilliseconds

# Level 2: Overall migration timing
if ($debugLevel -ge 2) {
    Write-Verbose "[database.migrate-metrics] Migration completed in ${migrationDuration}ms"
    Write-Verbose "[database.migrate-metrics] Total metrics imported: $importedCount"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    Write-Host "  [database.migrate-metrics] Performance - Duration: ${migrationDuration}ms, Metrics imported: $importedCount" -ForegroundColor DarkGray
}

Write-ScriptMessage -Message "Migration complete. Imported $importedCount metrics total." -LogLevel Info
