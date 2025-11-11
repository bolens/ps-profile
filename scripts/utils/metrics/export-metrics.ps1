<#
scripts/utils/export-metrics.ps1

.SYNOPSIS
    Exports code metrics and performance metrics to CSV or JSON formats.

.DESCRIPTION
    Collects code metrics and optionally performance metrics, then exports them
    to CSV or JSON format for analysis, reporting, or integration with other tools.

.PARAMETER OutputFormat
    Output format: CSV or JSON. Defaults to JSON.

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
    [ValidateSet('CSV', 'JSON')]
    [string]$OutputFormat = 'JSON',

    [string]$OutputPath = $null,

    [switch]$IncludePerformance,

    [switch]$IncludeCodeMetrics = $true
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Exporting metrics..." -LogLevel Info

$exportData = [ordered]@{
    Timestamp = [DateTime]::UtcNow.ToString('o')
    Source    = 'PowerShell Profile Codebase'
}

# Collect code metrics
if ($IncludeCodeMetrics) {
    Write-ScriptMessage -Message "Collecting code metrics..." -LogLevel Info
    $codeMetrics = Get-CodeMetrics -Path $repoRoot -Recurse
    $exportData.CodeMetrics = $codeMetrics
}

# Collect performance metrics if available
if ($IncludePerformance) {
    Write-ScriptMessage -Message "Collecting performance metrics..." -LogLevel Info
    $baselineFile = Join-Path $repoRoot 'scripts' 'data' 'performance-baseline.json'
    $benchmarkFile = Join-Path $repoRoot 'scripts' 'data' 'startup-benchmark.csv'
    
    $performanceData = @{}
    
    if (Test-Path -Path $baselineFile) {
        try {
            $baseline = Get-Content -Path $baselineFile -Raw | ConvertFrom-Json
            $performanceData.Baseline = $baseline
        }
        catch {
            Write-ScriptMessage -Message "Failed to load performance baseline: $($_.Exception.Message)" -IsWarning
        }
    }
    
    if (Test-Path -Path $benchmarkFile) {
        try {
            $benchmark = Import-Csv -Path $benchmarkFile
            $performanceData.Benchmark = $benchmark
        }
        catch {
            Write-ScriptMessage -Message "Failed to load benchmark data: $($_.Exception.Message)" -IsWarning
        }
    }
    
    if ($performanceData.Count -gt 0) {
        $exportData.PerformanceMetrics = $performanceData
    }
}

# Determine output path
if (-not $OutputPath) {
    $dataDir = Join-Path $repoRoot 'scripts' 'data'
    Ensure-DirectoryExists -Path $dataDir
    $extension = if ($OutputFormat -eq 'CSV') { 'csv' } else { 'json' }
    $OutputPath = Join-Path $dataDir "metrics-export.$extension"
}

# Export data
try {
    if ($OutputFormat -eq 'CSV') {
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
            foreach ($fileMetric in $exportData.CodeMetrics.FileMetrics) {
                $csvData.Add([PSCustomObject]@{
                        MetricType = 'FileMetrics'
                        File       = $fileMetric.File
                        Lines      = $fileMetric.Lines
                        Functions  = $fileMetric.Functions
                        Complexity = $fileMetric.Complexity
                    })
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
        $exportData | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    }
    
    Write-ScriptMessage -Message "Metrics exported to: $OutputPath" -LogLevel Info
    Write-ScriptMessage -Message "Format: $OutputFormat" -LogLevel Info
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to export metrics: $($_.Exception.Message)" -ErrorRecord $_
}

Exit-WithCode -ExitCode $EXIT_SUCCESS

