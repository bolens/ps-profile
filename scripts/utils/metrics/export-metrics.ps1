<#
scripts/utils/export-metrics.ps1

.SYNOPSIS
    Exports code metrics and performance metrics to CSV or JSON formats.

.DESCRIPTION
    Collects code metrics and optionally performance metrics, then exports them
    to CSV or JSON format for analysis, reporting, or integration with other tools.

.PARAMETER OutputFormat
    Output format. Must be an OutputFormat enum value. Defaults to Json.

.PARAMETER OutputPath
    Output file path. Defaults to scripts/data/metrics-export.{format}.

.PARAMETER IncludePerformance
    If specified, includes performance metrics from benchmark data.

.PARAMETER IncludeCodeMetrics
    If specified, includes code metrics. Defaults to true.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\export-metrics.ps1

    Exports code metrics to JSON format.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\export-metrics.ps1 -OutputFormat CSV -OutputPath metrics.csv

    Exports metrics to CSV format with custom path.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\export-metrics.ps1 -IncludePerformance

    Exports both code metrics and performance metrics.
#>

param(
    [object]$OutputFormat = [OutputFormat]::Json,  # Accepts OutputFormat enum or string for backward compatibility

    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = $null,

    [switch]$IncludePerformance,

    [switch]$IncludeCodeMetrics = $true
)

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import CommonEnums for OutputFormat enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

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
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Convert enum to string (normalize to uppercase for file extension)
$outputFormatString = $OutputFormat.ToString().ToUpper()

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.export] Starting metrics export"
    Write-Verbose "[metrics.export] Output format: $outputFormatString"
    Write-Verbose "[metrics.export] Include code metrics: $IncludeCodeMetrics, Include performance: $IncludePerformance"
}

Write-ScriptMessage -Message "Exporting metrics..." -LogLevel Info

$exportData = [ordered]@{
    Timestamp = [DateTime]::UtcNow.ToString('o')
    Source    = 'PowerShell Profile Codebase'
}

# Collect code metrics
if ($IncludeCodeMetrics) {
    Write-ScriptMessage -Message "Collecting code metrics..." -LogLevel Info
    
    # Level 1: Code metrics collection start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.export] Collecting code metrics from: $repoRoot"
    }
    
    $codeMetricsStartTime = Get-Date
    try {
        $codeMetrics = Get-CodeMetrics -Path $repoRoot -Recurse -ErrorAction Stop
        $codeMetricsDuration = ((Get-Date) - $codeMetricsStartTime).TotalMilliseconds
        
        # Level 2: Code metrics timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[metrics.export] Code metrics collected in ${codeMetricsDuration}ms"
            if ($codeMetrics) {
                Write-Verbose "[metrics.export] Code metrics: $($codeMetrics.Count) metric(s)"
            }
        }
        if ($codeMetrics) {
            $exportData.CodeMetrics = $codeMetrics
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.export.collect-code' -Context @{
                repo_root = $repoRoot
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect code metrics: $($_.Exception.Message)" -IsWarning
        }
        # Continue without code metrics if collection fails
    }
}

# Collect performance metrics if available
if ($IncludePerformance) {
    Write-ScriptMessage -Message "Collecting performance metrics..." -LogLevel Info
    
    # Level 1: Performance metrics collection start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.export] Collecting performance metrics"
    }
    
    $perfMetricsStartTime = Get-Date
    $baselineFile = Join-Path $repoRoot 'scripts' 'data' 'performance-baseline.json'
    $benchmarkFile = Join-Path $repoRoot 'scripts' 'data' 'startup-benchmark.csv'
    
    $performanceData = @{}
    
    if (Test-Path -Path $baselineFile) {
        try {
            $baseline = Read-JsonFile -Path $baselineFile -ErrorAction SilentlyContinue
            if ($null -ne $baseline) {
                $performanceData.Baseline = $baseline
            }
        }
        catch {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to load performance baseline" -OperationName 'metrics.export.load-baseline' -Context @{
                    baseline_file = $baselineFile
                } -Code 'BaselineLoadFailed'
            }
            else {
                Write-ScriptMessage -Message "Failed to load performance baseline: $($_.Exception.Message)" -IsWarning
            }
        }
    }
    
    if (Test-Path -Path $benchmarkFile) {
        try {
            $benchmark = Import-Csv -Path $benchmarkFile
            $performanceData.Benchmark = $benchmark
        }
        catch {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to load benchmark data" -OperationName 'metrics.export.load-benchmark' -Context @{
                    benchmark_file = $benchmarkFile
                } -Code 'BenchmarkLoadFailed'
            }
            else {
                Write-ScriptMessage -Message "Failed to load benchmark data: $($_.Exception.Message)" -IsWarning
            }
        }
    }
    
    if ($performanceData.Count -gt 0) {
        $exportData.PerformanceMetrics = $performanceData
    }
    
    $perfMetricsDuration = ((Get-Date) - $perfMetricsStartTime).TotalMilliseconds
    
    # Level 2: Performance metrics timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[metrics.export] Performance metrics collected in ${perfMetricsDuration}ms"
    }
}

# Level 1: Export start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.export] Preparing export data"
}

# Determine output path
if (-not $OutputPath) {
    $dataDir = Join-Path $repoRoot 'scripts' 'data'
    Ensure-DirectoryExists -Path $dataDir
    $extension = if ($outputFormatString -eq 'CSV') { 'csv' } else { 'json' }
    $OutputPath = Join-Path $dataDir "metrics-export.$extension"
}

# Export data
$exportStartTime = Get-Date
try {
    # Level 1: Export execution
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.export] Exporting data to: $OutputPath (Format: $outputFormatString)"
    }
    
    if ($outputFormatString -eq 'CSV') {
        # For CSV, flatten the structure
        $csvData = [System.Collections.Generic.List[PSCustomObject]]::new()
        
        if ($exportData.CodeMetrics) {
            $csvData.Add([PSCustomObject]@{
                    MetricType         = 'CodeMetrics'
                    Timestamp          = $exportData.Timestamp
                    TotalFiles         = $exportData.CodeMetrics.TotalFiles
                    TotalLines         = $exportData.CodeMetrics.TotalLines
                    TotalFunctions     = $exportData.CodeMetrics.TotalFunctions
                    TotalComplexity    = $exportData.CodeMetrics.TotalComplexity
                    DuplicateFunctions = $exportData.CodeMetrics.DuplicateFunctions
                })
            
            # Add file-level metrics
            if ($exportData.CodeMetrics.FileMetrics) {
                foreach ($fileMetric in $exportData.CodeMetrics.FileMetrics) {
                    try {
                        $csvData.Add([PSCustomObject]@{
                                MetricType = 'FileMetrics'
                                File       = $fileMetric.File
                                Lines      = $fileMetric.Lines
                                Functions  = $fileMetric.Functions
                                Complexity = $fileMetric.Complexity
                            })
                    }
                    catch {
                        # Skip individual file metrics that fail to process
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Failed to process file metric" -OperationName 'metrics.export.process-file-metric' -Context @{
                                file = if ($fileMetric) { $fileMetric.File } else { 'unknown' }
                            } -Code 'FileMetricProcessingFailed'
                        }
                    }
                }
            }
        }
        
        if ($exportData.PerformanceMetrics) {
            if ($exportData.PerformanceMetrics.Baseline) {
                $csvData.Add([PSCustomObject]@{
                        MetricType      = 'PerformanceBaseline'
                        FullStartupMean = $exportData.PerformanceMetrics.Baseline.FullStartupMean
                        Timestamp       = $exportData.PerformanceMetrics.Baseline.Timestamp
                    })
            }
        }
        
        $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    }
    else {
        # JSON export
        Write-JsonFile -Path $OutputPath -InputObject $exportData -Depth 10 -EnsureDirectory
    }
    
    $exportDuration = ((Get-Date) - $exportStartTime).TotalMilliseconds
    
    # Level 2: Export timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[metrics.export] Export completed in ${exportDuration}ms"
    }
    
    # Level 3: Performance breakdown
    if ($debugLevel -ge 3) {
        $totalSize = if (Test-Path $OutputPath) { (Get-Item $OutputPath).Length } else { 0 }
        Write-Host "  [metrics.export] Performance - Export: ${exportDuration}ms, File size: ${totalSize} bytes" -ForegroundColor DarkGray
    }
    
    Write-ScriptMessage -Message "Metrics exported to: $OutputPath" -LogLevel Info
    Write-ScriptMessage -Message "Format: $outputFormatString" -LogLevel Info
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to export metrics: $($_.Exception.Message)" -ErrorRecord $_
}

Exit-WithCode -ExitCode [ExitCode]::Success



