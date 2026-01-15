<#
scripts/utils/database/populate-performance-metrics.ps1

.SYNOPSIS
    Populates the performance metrics database with current metrics.

.DESCRIPTION
    Collects and stores performance metrics in the SQLite database:
    - Code metrics (lines, functions, complexity, quality score, test coverage)
    - Distribution metrics (max/min file sizes, high complexity files)
    - Per-path metrics (breakdown by scripts vs profile.d)
    - Code similarity metrics
    - Test metrics (if test results available)
    - Startup benchmarks
    - Optionally migrates existing JSON/CSV files

.PARAMETER IncludeCodeMetrics
    Collect and store code metrics. Defaults to true.

.PARAMETER IncludeStartupBenchmark
    Run startup benchmark and store results. Defaults to true.

.PARAMETER IncludeMigration
    Migrate existing JSON/CSV files to database. Defaults to false.

.PARAMETER BenchmarkIterations
    Number of iterations for startup benchmark. Defaults to 5.

.PARAMETER IncludeDocumentationMetrics
    Collect and store documentation coverage metrics. Defaults to false (can be slow).

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\database\populate-performance-metrics.ps1

    Populates database with code metrics and startup benchmarks.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\database\populate-performance-metrics.ps1 -IncludeMigration

    Also migrates existing JSON/CSV files to the database.

.NOTES
    The script collects comprehensive metrics including:
    - Basic metrics: files, lines, functions, complexity, duplicates
    - Quality metrics: quality score, test coverage percentage
    - Distribution metrics: max/min file sizes, high complexity files
    - Per-path breakdown: metrics for scripts/ and profile.d/ separately
    - Code similarity: count of similar code blocks
    - Lint metrics: PSScriptAnalyzer violations by severity (if report available)
    - Test metrics: test counts, pass/fail rates, duration (if available)
    - Documentation metrics: function documentation coverage (optional, can be slow)
    - Git metrics: commit count, contributors, branches, tags (if repository)
    - Alias metrics: total aliases, alias-to-function ratio (if docs available)
    - Security metrics: security issues count by severity (if scan report available)
    - Fragment dependencies: dependency counts and averages (if config available)
    - Startup performance: full startup time and per-fragment timings
    
    Progressive Improvement:
    - Each metric is written to the database immediately after capture
    - Individual metric write failures don't prevent other metrics from being stored
    - You can run the script multiple times to progressively build up your metrics database
    - Each run adds new timestamped entries, enabling historical trend analysis
#>

param(
    [switch]$IncludeCodeMetrics = $true,
    
    [switch]$IncludeStartupBenchmark = $true,
    
    [switch]$IncludeMigration,
    
    [switch]$IncludeDocumentationMetrics,
    
    [int]$BenchmarkIterations = 5
)

# Import shared utilities
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking

# Import Performance Metrics Database
$perfMetricsModule = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'database' 'PerformanceMetricsDatabase.psm1'
if (-not (Test-Path -LiteralPath $perfMetricsModule)) {
    Write-ScriptMessage -Message "Performance Metrics Database module not found: $perfMetricsModule" -IsWarning
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Performance Metrics Database module not found"
}

Import-Module $perfMetricsModule -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Track script start time for performance metrics
$scriptStartTime = Get-Date

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.setup' -Context @{
            script_path = $PSScriptRoot
        }
    }
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

Write-ScriptMessage -Message "Populating Performance Metrics Database..." -LogLevel Info

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.populate] Starting metrics collection - CodeMetrics: $IncludeCodeMetrics, StartupBenchmark: $IncludeStartupBenchmark, Migration: $IncludeMigration"
}

# Initialize database
if (-not (Initialize-PerformanceMetricsDb)) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Failed to initialize performance metrics database" -OperationName 'metrics.populate.init' -Code 'DB_INIT_FAILED'
    }
    else {
        Write-ScriptMessage -Message "Failed to initialize performance metrics database" -IsWarning
    }
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to initialize performance metrics database"
}

$environment = if ($env:CI) { 'CI' } else { 'local' }
$metricsCount = 0
$failureCount = 0

# Helper function to safely add a metric (allows progressive improvement)
# Each metric is written immediately to the database via Add-PerformanceMetric.
# This means:
# - Metrics are persisted as soon as they're captured (not batched)
# - If the script fails partway through, already-written metrics remain in the database
# - You can run the script multiple times to progressively build up your metrics history
# - Individual metric write failures don't prevent other metrics from being stored
$safeAddMetric = {
    param(
        [string]$MetricType,
        [string]$MetricName,
        [double]$Value,
        [string]$Unit = 'count',
        [hashtable]$Metadata = @{}
    )
    try {
        Add-PerformanceMetric -MetricType $MetricType -MetricName $MetricName -Value $Value -Unit $Unit -Environment $environment -Metadata $Metadata
        return $true
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to store metric" -OperationName 'metrics.populate.store' -Context @{
                metric_type = $MetricType
                metric_name = $MetricName
                value       = $Value
                unit        = $Unit
            } -Code 'METRIC_STORE_FAILED'
        }
        else {
            Write-ScriptMessage -Message "Failed to store $MetricName metric: $($_.Exception.Message)" -IsWarning
        }
        return $false
    }
}

# Collect and store code metrics
# Note: Each metric is written immediately to the database, allowing progressive improvement.
# If the script fails partway through, already-written metrics remain in the database.
if ($IncludeCodeMetrics) {
    Write-ScriptMessage -Message "Collecting code metrics..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.code] Starting code metrics collection"
    }
    
    $codeMetricsStartTime = Get-Date
    
    try {
        $collectScript = Join-Path $repoRoot 'scripts' 'utils' 'metrics' 'collect-code-metrics.ps1'
        
        # Run collect-code-metrics script to generate JSON file (continue on failure)
        if (Test-Path -LiteralPath $collectScript) {
            try {
                & $collectScript -ErrorAction SilentlyContinue
            }
            catch {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Code metrics collection script failed" -OperationName 'metrics.populate.code.collect' -Context @{
                        script_path = $collectScript
                    } -Code 'COLLECT_SCRIPT_FAILED'
                }
                else {
                    Write-ScriptMessage -Message "Code metrics collection script failed: $($_.Exception.Message)" -IsWarning
                }
                $failureCount++
            }
        }
        else {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Code metrics collection script not found" -OperationName 'metrics.populate.code.collect' -Context @{
                    script_path = $collectScript
                } -Code 'SCRIPT_NOT_FOUND'
            }
            else {
                Write-ScriptMessage -Message "Code metrics collection script not found: $collectScript" -IsWarning
            }
            $failureCount++
        }
        
        # Read the generated code metrics JSON
        $codeMetricsFile = Join-Path $repoRoot 'scripts' 'data' 'code-metrics.json'
        if (Test-Path -LiteralPath $codeMetricsFile) {
            try {
                $codeMetrics = Read-JsonFile -Path $codeMetricsFile -ErrorAction SilentlyContinue
                if (-not $codeMetrics) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to read or parse code metrics file" -OperationName 'metrics.populate.code.read' -Context @{
                            file_path = $codeMetricsFile
                        } -Code 'PARSE_FAILED'
                    }
                    else {
                        Write-ScriptMessage -Message "Failed to read or parse code metrics file: $codeMetricsFile" -IsWarning
                    }
                    $failureCount++
                    return
                }
            }
            catch {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.code.read' -Context @{
                        file_path = $codeMetricsFile
                    }
                }
                else {
                    Write-ScriptMessage -Message "Failed to read code metrics file: $($_.Exception.Message)" -IsWarning
                }
                $failureCount++
                return
            }
            
            # Store code metrics in database (each write is independent for progressive improvement)
            if ($codeMetrics.TotalFiles) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'total_files' -Value $codeMetrics.TotalFiles -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($codeMetrics.TotalLines) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'total_lines' -Value $codeMetrics.TotalLines -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($codeMetrics.TotalFunctions) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'total_functions' -Value $codeMetrics.TotalFunctions -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($codeMetrics.TotalComplexity) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'total_complexity' -Value $codeMetrics.TotalComplexity -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($codeMetrics.DuplicateFunctions) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'duplicate_functions' -Value $codeMetrics.DuplicateFunctions -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($codeMetrics.AverageLinesPerFile) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'average_lines_per_file' -Value $codeMetrics.AverageLinesPerFile -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($codeMetrics.AverageFunctionsPerFile) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'average_functions_per_file' -Value $codeMetrics.AverageFunctionsPerFile -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($codeMetrics.AverageComplexityPerFile) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'average_complexity_per_file' -Value $codeMetrics.AverageComplexityPerFile -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            # Store test coverage if available
            if ($codeMetrics.TestCoverage -and $codeMetrics.TestCoverage.CoveragePercent) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'test_coverage_percent' -Value $codeMetrics.TestCoverage.CoveragePercent -Unit 'percent' -Metadata @{
                        Source       = 'populate_performance_metrics'
                        CoveredLines = $codeMetrics.TestCoverage.CoveredLines
                        TotalLines   = $codeMetrics.TestCoverage.TotalLines
                    }) {
                    $metricsCount++
                }
            }
            
            # Store quality score if available
            if ($codeMetrics.QualityScore -and $codeMetrics.QualityScore.Score) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'quality_score' -Value $codeMetrics.QualityScore.Score -Unit 'score' -Metadata @{
                        Source          = 'populate_performance_metrics'
                        ComponentScores = $codeMetrics.QualityScore.ComponentScores
                    }) {
                    $metricsCount++
                }
            }
            
            # Store code similarity count if available
            if ($codeMetrics.CodeSimilarity -and $codeMetrics.CodeSimilarity.Count) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'code_similarity_count' -Value $codeMetrics.CodeSimilarity.Count -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            # Store distribution metrics (max/min file sizes, complexity)
            if ($codeMetrics.PathMetrics -and $codeMetrics.PathMetrics.Count -gt 0) {
                $allFileMetrics = @()
                foreach ($pathMetric in $codeMetrics.PathMetrics) {
                    if ($pathMetric.FileMetrics) {
                        $allFileMetrics += $pathMetric.FileMetrics
                    }
                }
                
                if ($allFileMetrics.Count -gt 0) {
                    # Max file size (lines)
                    $maxFileLines = ($allFileMetrics | Measure-Object -Property Lines -Maximum).Maximum
                    if ($maxFileLines) {
                        if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'max_file_lines' -Value $maxFileLines -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    # Min file size (lines)
                    $minFileLines = ($allFileMetrics | Measure-Object -Property Lines -Minimum).Minimum
                    if ($minFileLines) {
                        if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'min_file_lines' -Value $minFileLines -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    # Max file complexity
                    $maxFileComplexity = ($allFileMetrics | Measure-Object -Property Complexity -Maximum).Maximum
                    if ($maxFileComplexity) {
                        if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'max_file_complexity' -Value $maxFileComplexity -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    # Files with high complexity (> 20)
                    $highComplexityFiles = ($allFileMetrics | Where-Object { $_.Complexity -gt 20 }).Count
                    if ($highComplexityFiles) {
                        if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'high_complexity_files' -Value $highComplexityFiles -Unit 'count' -Metadata @{
                                Source    = 'populate_performance_metrics'
                                Threshold = 20
                            }) {
                            $metricsCount++
                        }
                    }
                    
                    # Files with many functions (> 10)
                    $manyFunctionsFiles = ($allFileMetrics | Where-Object { $_.Functions -gt 10 }).Count
                    if ($manyFunctionsFiles) {
                        if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'many_functions_files' -Value $manyFunctionsFiles -Unit 'count' -Metadata @{
                                Source    = 'populate_performance_metrics'
                                Threshold = 10
                            }) {
                            $metricsCount++
                        }
                    }
                }
            }
            
            # Store per-path metrics (fragments/modules breakdown)
            if ($codeMetrics.PathMetrics -and $codeMetrics.PathMetrics.Count -gt 0) {
                foreach ($pathMetric in $codeMetrics.PathMetrics) {
                    $pathName = if ($pathMetric.Path) {
                        # Extract meaningful name from path (e.g., "scripts" or "profile.d")
                        $pathParts = $pathMetric.Path -split [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)
                        if ($pathParts.Count -gt 0) {
                            $pathParts[-1]
                        }
                        else {
                            $pathMetric.Path
                        }
                    }
                    else {
                        'unknown'
                    }
                    
                    # Store per-path file count
                    if ($pathMetric.TotalFiles) {
                        if (& $safeAddMetric -MetricType 'code_metrics' -MetricName "path_${pathName}_files" -Value $pathMetric.TotalFiles -Unit 'count' -Metadata @{
                                Source = 'populate_performance_metrics'
                                Path   = $pathMetric.Path
                            }) {
                            $metricsCount++
                        }
                    }
                    
                    # Store per-path line count
                    if ($pathMetric.TotalLines) {
                        if (& $safeAddMetric -MetricType 'code_metrics' -MetricName "path_${pathName}_lines" -Value $pathMetric.TotalLines -Unit 'count' -Metadata @{
                                Source = 'populate_performance_metrics'
                                Path   = $pathMetric.Path
                            }) {
                            $metricsCount++
                        }
                    }
                    
                    # Store per-path function count
                    if ($pathMetric.TotalFunctions) {
                        if (& $safeAddMetric -MetricType 'code_metrics' -MetricName "path_${pathName}_functions" -Value $pathMetric.TotalFunctions -Unit 'count' -Metadata @{
                                Source = 'populate_performance_metrics'
                                Path   = $pathMetric.Path
                            }) {
                            $metricsCount++
                        }
                    }
                }
            }
            
            # Store fragment count (profile.d fragments)
            $fragmentDir = Join-Path $repoRoot 'profile.d'
            if (Test-Path -LiteralPath $fragmentDir -PathType Container) {
                $fragmentCount = (Get-ChildItem -Path $fragmentDir -Filter '*.ps1' -File -ErrorAction SilentlyContinue).Count
                if ($fragmentCount -gt 0) {
                    if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'fragment_count' -Value $fragmentCount -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                        $metricsCount++
                    }
                }
            }
            
            $codeMetricsDuration = ((Get-Date) - $codeMetricsStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[metrics.populate.code] Code metrics collection completed in $([Math]::Round($codeMetricsDuration, 1))ms"
            }
            
            # Level 3: Detailed breakdown
            if ($debugLevel -ge 3) {
                Write-Host "  [metrics.populate.code] Performance - Duration: $([Math]::Round($codeMetricsDuration, 1))ms, Metrics stored: $metricsCount" -ForegroundColor DarkGray
            }
            
            Write-ScriptMessage -Message "Stored $metricsCount code metrics in database" -LogLevel Info
        }
        else {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Code metrics file not found after collection" -OperationName 'metrics.populate.code' -Context @{
                    file_path = $codeMetricsFile
                } -Code 'FILE_NOT_FOUND'
            }
            else {
                Write-ScriptMessage -Message "Code metrics file not found after collection: $codeMetricsFile" -IsWarning
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.code' -Context @{
                include_code_metrics = $IncludeCodeMetrics
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect or store code metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Collect and store lint metrics (PSScriptAnalyzer violations) if available
$lintReportPath = Join-Path $repoRoot 'scripts' 'data' 'psscriptanalyzer-report.json'
if (Test-Path -LiteralPath $lintReportPath) {
    Write-ScriptMessage -Message "Collecting lint metrics from PSScriptAnalyzer report..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.lint] Collecting lint metrics from: $lintReportPath"
    }
    
    try {
        $lintReport = Read-JsonFile -Path $lintReportPath -ErrorAction SilentlyContinue
        
        if ($lintReport -and $lintReport.Count -gt 0) {
            # Count violations by severity
            $errorCount = ($lintReport | Where-Object { $_.Severity -eq 'Error' }).Count
            $warningCount = ($lintReport | Where-Object { $_.Severity -eq 'Warning' }).Count
            $infoCount = ($lintReport | Where-Object { $_.Severity -eq 'Information' }).Count
            $totalViolations = $lintReport.Count
            
            # Store violation counts (each write is independent)
            if ($totalViolations -ge 0) {
                if (& $safeAddMetric -MetricType 'code_quality' -MetricName 'lint_total_violations' -Value $totalViolations -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($errorCount -ge 0) {
                if (& $safeAddMetric -MetricType 'code_quality' -MetricName 'lint_errors' -Value $errorCount -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($warningCount -ge 0) {
                if (& $safeAddMetric -MetricType 'code_quality' -MetricName 'lint_warnings' -Value $warningCount -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($infoCount -ge 0) {
                if (& $safeAddMetric -MetricType 'code_quality' -MetricName 'lint_information' -Value $infoCount -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            # Count unique rule violations
            $uniqueRules = ($lintReport | Select-Object -ExpandProperty RuleName -Unique).Count
            if ($uniqueRules) {
                if (& $safeAddMetric -MetricType 'code_quality' -MetricName 'lint_unique_rules' -Value $uniqueRules -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            Write-ScriptMessage -Message "Stored lint metrics in database" -LogLevel Info
            
            # Level 2: Summary
            if ($debugLevel -ge 2) {
                Write-Verbose "[metrics.populate.lint] Lint metrics - Total: $totalViolations, Errors: $errorCount, Warnings: $warningCount, Info: $infoCount"
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.lint' -Context @{
                report_path = $lintReportPath
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect lint metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Collect and store test metrics if available
$testResultsPath = Join-Path $repoRoot 'scripts' 'data' 'test-results.json'
if (Test-Path -LiteralPath $testResultsPath) {
    Write-ScriptMessage -Message "Collecting test metrics from recent test results..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.test] Collecting test metrics from: $testResultsPath"
    }
    
    try {
        $testResults = Read-JsonFile -Path $testResultsPath -ErrorAction SilentlyContinue
        
        if ($testResults -and $testResults.TestResults) {
            $tr = $testResults.TestResults
            
            # Store test counts (each write is independent)
            if ($tr.TotalTests) {
                if (& $safeAddMetric -MetricType 'test_metrics' -MetricName 'total_tests' -Value $tr.TotalTests -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($tr.PassedTests) {
                if (& $safeAddMetric -MetricType 'test_metrics' -MetricName 'passed_tests' -Value $tr.PassedTests -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($tr.FailedTests) {
                if (& $safeAddMetric -MetricType 'test_metrics' -MetricName 'failed_tests' -Value $tr.FailedTests -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($tr.SkippedTests) {
                if (& $safeAddMetric -MetricType 'test_metrics' -MetricName 'skipped_tests' -Value $tr.SkippedTests -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            # Store success rate
            if ($tr.SuccessRate) {
                if (& $safeAddMetric -MetricType 'test_metrics' -MetricName 'success_rate' -Value $tr.SuccessRate -Unit 'percent' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            # Store test duration if available
            if ($tr.Duration) {
                $durationMs = if ($tr.Duration -is [TimeSpan]) {
                    $tr.Duration.TotalMilliseconds
                }
                elseif ($tr.Duration -is [double] -or $tr.Duration -is [int]) {
                    $tr.Duration
                }
                else {
                    $null
                }
                
                if ($null -ne $durationMs) {
                    if (& $safeAddMetric -MetricType 'test_metrics' -MetricName 'test_duration' -Value $durationMs -Unit 'ms' -Metadata @{ Source = 'populate_performance_metrics' }) {
                        $metricsCount++
                    }
                }
            }
            
            Write-ScriptMessage -Message "Stored test metrics in database" -LogLevel Info
            
            # Level 2: Summary
            if ($debugLevel -ge 2) {
                Write-Verbose "[metrics.populate.test] Test metrics - Total: $($tr.TotalTests), Passed: $($tr.PassedTests), Failed: $($tr.FailedTests), Success rate: $($tr.SuccessRate)%"
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.test' -Context @{
                results_path = $testResultsPath
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect test metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Run startup benchmark (this already writes to database)
if ($IncludeStartupBenchmark) {
    Write-ScriptMessage -Message "Running startup benchmark..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.benchmark] Starting startup benchmark with $BenchmarkIterations iterations"
    }
    
    $benchmarkStartTime = Get-Date
    
    try {
        $benchmarkScript = Join-Path $repoRoot 'scripts' 'utils' 'metrics' 'benchmark-startup.ps1'
        
        if (Test-Path -LiteralPath $benchmarkScript) {
            & $benchmarkScript -Iterations $BenchmarkIterations -ErrorAction Stop
            $benchmarkDuration = ((Get-Date) - $benchmarkStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[metrics.populate.benchmark] Startup benchmark completed in $([Math]::Round($benchmarkDuration, 1))ms"
            }
            
            Write-ScriptMessage -Message "Startup benchmark completed and metrics stored in database" -LogLevel Info
        }
        else {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Benchmark script not found" -OperationName 'metrics.populate.benchmark' -Context @{
                    script_path = $benchmarkScript
                } -Code 'SCRIPT_NOT_FOUND'
            }
            else {
                Write-ScriptMessage -Message "Benchmark script not found: $benchmarkScript" -IsWarning
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.benchmark' -Context @{
                iterations  = $BenchmarkIterations
                script_path = $benchmarkScript
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to run startup benchmark: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Migrate existing JSON/CSV files if requested
if ($IncludeMigration) {
    Write-ScriptMessage -Message "Migrating existing metrics files..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.migrate] Starting migration of existing metrics files"
    }
    
    try {
        $migrateScript = Join-Path $repoRoot 'scripts' 'utils' 'database' 'migrate-metrics-to-sqlite.ps1'
        
        if (Test-Path -LiteralPath $migrateScript) {
            $baselineFile = Join-Path $repoRoot 'scripts' 'data' 'performance-baseline.json'
            $benchmarkFile = Join-Path $repoRoot 'scripts' 'data' 'startup-benchmark.csv'
            $metricsHistoryPath = Join-Path $repoRoot 'scripts' 'data' 'history'
            
            $migrateParams = @{}
            if (Test-Path -LiteralPath $baselineFile) {
                $migrateParams['BaselineFile'] = $baselineFile
            }
            if (Test-Path -LiteralPath $benchmarkFile) {
                $migrateParams['BenchmarkFile'] = $benchmarkFile
            }
            if (Test-Path -LiteralPath $metricsHistoryPath -PathType Container) {
                $migrateParams['MetricsHistoryPath'] = $metricsHistoryPath
            }
            
            if ($migrateParams.Count -gt 0) {
                & $migrateScript @migrateParams -ErrorAction Stop
                Write-ScriptMessage -Message "Migration completed" -LogLevel Info
            }
            else {
                Write-ScriptMessage -Message "No existing metrics files found to migrate" -LogLevel Info
            }
        }
        else {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Migration script not found" -OperationName 'metrics.populate.migrate' -Context @{
                    script_path = $migrateScript
                } -Code 'SCRIPT_NOT_FOUND'
            }
            else {
                Write-ScriptMessage -Message "Migration script not found: $migrateScript" -IsWarning
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.migrate' -Context @{
                include_migration = $IncludeMigration
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to migrate existing metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Collect and store documentation coverage metrics if requested
if ($IncludeDocumentationMetrics) {
    Write-ScriptMessage -Message "Collecting documentation coverage metrics..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.docs] Starting documentation coverage analysis"
    }
    
    $docsStartTime = Get-Date
    
    try {
        Import-LibModule -ModuleName 'CommentHelp' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue
        Import-LibModule -ModuleName 'AstParsing' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue
        Import-LibModule -ModuleName 'FileContent' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue
        
        if ((Get-Command Test-FunctionHasHelp -ErrorAction SilentlyContinue) -and
            (Get-Command Get-PowerShellAst -ErrorAction SilentlyContinue) -and
            (Get-Command Get-FunctionsFromAst -ErrorAction SilentlyContinue)) {
            
            $totalFunctions = 0
            $documentedFunctions = 0
            $pathsToCheck = @(
                Join-Path $repoRoot 'scripts'
                Join-Path $repoRoot 'profile.d'
            ) | Where-Object { Test-Path $_ }
            
            foreach ($checkPath in $pathsToCheck) {
                $psFiles = Get-ChildItem -Path $checkPath -Filter '*.ps1' -Recurse -File | Where-Object {
                    $_.FullName -notmatch '\\\.git\\' -and
                    $_.FullName -notmatch '\\tests\\'
                }
                
                foreach ($psFile in $psFiles) {
                    try {
                        $content = if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
                            Read-FileContent -Path $psFile.FullName
                        }
                        else {
                            Get-Content -Path $psFile.FullName -Raw
                        }
                        
                        if ([string]::IsNullOrWhiteSpace($content)) {
                            continue
                        }
                        
                        $ast = Get-PowerShellAst -Path $psFile.FullName
                        $functionAsts = Get-FunctionsFromAst -Ast $ast
                        
                        foreach ($funcAst in $functionAsts) {
                            # Skip internal/global functions
                            if ($funcAst.Name -match ':') {
                                continue
                            }
                            
                            $totalFunctions++
                            $hasHelp = Test-FunctionHasHelp -FuncAst $funcAst -Content $content -CheckBody
                            if ($hasHelp) {
                                $documentedFunctions++
                            }
                        }
                    }
                    catch {
                        # Skip files that can't be parsed
                        continue
                    }
                }
            }
            
            if ($totalFunctions -gt 0) {
                $docCoveragePercent = [Math]::Round(($documentedFunctions / $totalFunctions) * 100, 2)
                
                # Store documentation metrics (each write is independent)
                if (& $safeAddMetric -MetricType 'code_quality' -MetricName 'documentation_coverage_percent' -Value $docCoveragePercent -Unit 'percent' -Metadata @{
                        Source              = 'populate_performance_metrics'
                        TotalFunctions      = $totalFunctions
                        DocumentedFunctions = $documentedFunctions
                    }) {
                    $metricsCount++
                }
                
                if (& $safeAddMetric -MetricType 'code_quality' -MetricName 'documented_functions' -Value $documentedFunctions -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
                
                if (& $safeAddMetric -MetricType 'code_quality' -MetricName 'undocumented_functions' -Value ($totalFunctions - $documentedFunctions) -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
                
                Write-ScriptMessage -Message "Documentation coverage: ${docCoveragePercent}% ($documentedFunctions/$totalFunctions functions)" -LogLevel Info
            }
        }
        else {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "CommentHelp module not available, skipping documentation metrics" -OperationName 'metrics.populate.docs' -Code 'MODULE_NOT_AVAILABLE'
            }
            else {
                Write-ScriptMessage -Message "CommentHelp module not available, skipping documentation metrics" -IsWarning
            }
        }
        
        # Level 2: Timing information
        if ($debugLevel -ge 2 -and $docsStartTime) {
            $docsDuration = ((Get-Date) - $docsStartTime).TotalMilliseconds
            Write-Verbose "[metrics.populate.docs] Documentation analysis completed in $([Math]::Round($docsDuration, 1))ms"
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.docs' -Context @{
                include_documentation_metrics = $IncludeDocumentationMetrics
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect documentation metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Collect and store Git repository metrics if available
if (Test-Path -LiteralPath (Join-Path $repoRoot '.git')) {
    Write-ScriptMessage -Message "Collecting Git repository metrics..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.git] Collecting Git repository metrics"
    }
    
    try {
        # Check if git command is available
        if (Get-Command git -ErrorAction SilentlyContinue) {
            # Try to use Get-GitStats if available (from git-enhanced fragment)
            if (Get-Command Get-GitStats -ErrorAction SilentlyContinue) {
                $gitStats = Get-GitStats -RepositoryPath $repoRoot -ErrorAction SilentlyContinue
                
                if ($gitStats) {
                    if ($gitStats.TotalCommits) {
                        if (& $safeAddMetric -MetricType 'repository' -MetricName 'git_total_commits' -Value $gitStats.TotalCommits -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    if ($gitStats.Contributors) {
                        if (& $safeAddMetric -MetricType 'repository' -MetricName 'git_contributors' -Value $gitStats.Contributors -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    if ($gitStats.Branches) {
                        if (& $safeAddMetric -MetricType 'repository' -MetricName 'git_branches' -Value $gitStats.Branches -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    if ($gitStats.Tags) {
                        if (& $safeAddMetric -MetricType 'repository' -MetricName 'git_tags' -Value $gitStats.Tags -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    Write-ScriptMessage -Message "Stored Git metrics in database" -LogLevel Info
                }
            }
            else {
                # Fallback: use git commands directly
                Push-Location $repoRoot
                try {
                    $totalCommits = [int](& git rev-list --count HEAD 2>$null)
                    if ($totalCommits -gt 0) {
                        if (& $safeAddMetric -MetricType 'repository' -MetricName 'git_total_commits' -Value $totalCommits -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    $branches = [int](& git branch -a 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines)
                    if ($branches -gt 0) {
                        if (& $safeAddMetric -MetricType 'repository' -MetricName 'git_branches' -Value $branches -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    $tags = [int](& git tag 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines)
                    if ($tags -gt 0) {
                        if (& $safeAddMetric -MetricType 'repository' -MetricName 'git_tags' -Value $tags -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                            $metricsCount++
                        }
                    }
                    
                    Write-ScriptMessage -Message "Stored Git metrics in database" -LogLevel Info
                }
                finally {
                    Pop-Location
                }
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.git' -Context @{
                repository_path = $repoRoot
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect Git metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Collect and store alias count if documentation is available
$docsApiPath = Join-Path $repoRoot 'docs' 'api' 'aliases'
if (Test-Path -LiteralPath $docsApiPath -PathType Container) {
    Write-ScriptMessage -Message "Collecting alias metrics from documentation..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.alias] Collecting alias metrics from: $docsApiPath"
    }
    
    try {
        $aliasFiles = Get-ChildItem -Path $docsApiPath -Filter '*.md' -File -ErrorAction SilentlyContinue
        $aliasCount = $aliasFiles.Count
        
        if ($aliasCount -gt 0) {
            if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'total_aliases' -Value $aliasCount -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                $metricsCount++
            }
            
            # Calculate alias-to-function ratio if we have function count
            if ($codeMetrics -and $codeMetrics.TotalFunctions -and $codeMetrics.TotalFunctions -gt 0) {
                $aliasToFunctionRatio = [Math]::Round($aliasCount / $codeMetrics.TotalFunctions, 2)
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'alias_to_function_ratio' -Value $aliasToFunctionRatio -Unit 'ratio' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            Write-ScriptMessage -Message "Stored alias metrics in database" -LogLevel Info
            
            # Level 2: Summary
            if ($debugLevel -ge 2) {
                Write-Verbose "[metrics.populate.alias] Alias metrics - Total aliases: $aliasCount"
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.alias' -Context @{
                docs_path = $docsApiPath
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect alias metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Collect and store security scan metrics if available
$securityReportPath = Join-Path $repoRoot 'scripts' 'data' 'security-scan-report.json'
if (Test-Path -LiteralPath $securityReportPath) {
    Write-ScriptMessage -Message "Collecting security scan metrics..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.security] Collecting security metrics from: $securityReportPath"
    }
    
    try {
        $securityReport = Read-JsonFile -Path $securityReportPath -ErrorAction SilentlyContinue
        
        if ($securityReport) {
            # Count security issues by severity
            $blockingIssues = 0
            $warningIssues = 0
            $totalSecurityIssues = 0
            
            if ($securityReport.BlockingIssues) {
                $blockingIssues = if ($securityReport.BlockingIssues -is [array]) { $securityReport.BlockingIssues.Count } else { 0 }
            }
            if ($securityReport.WarningIssues) {
                $warningIssues = if ($securityReport.WarningIssues -is [array]) { $securityReport.WarningIssues.Count } else { 0 }
            }
            if ($securityReport.SecurityIssues) {
                $totalSecurityIssues = if ($securityReport.SecurityIssues -is [array]) { $securityReport.SecurityIssues.Count } else { 0 }
            }
            elseif ($blockingIssues -or $warningIssues) {
                $totalSecurityIssues = $blockingIssues + $warningIssues
            }
            
            if ($totalSecurityIssues -ge 0) {
                if (& $safeAddMetric -MetricType 'security' -MetricName 'security_issues_total' -Value $totalSecurityIssues -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($blockingIssues -ge 0) {
                if (& $safeAddMetric -MetricType 'security' -MetricName 'security_blocking_issues' -Value $blockingIssues -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($warningIssues -ge 0) {
                if (& $safeAddMetric -MetricType 'security' -MetricName 'security_warning_issues' -Value $warningIssues -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            Write-ScriptMessage -Message "Stored security metrics in database" -LogLevel Info
            
            # Level 2: Summary
            if ($debugLevel -ge 2) {
                Write-Verbose "[metrics.populate.security] Security metrics - Total: $totalSecurityIssues, Blocking: $blockingIssues, Warnings: $warningIssues"
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.security' -Context @{
                report_path = $securityReportPath
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect security metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Collect fragment dependency metrics if available
$fragmentConfigPath = Join-Path $repoRoot 'profile.d' 'fragment-config.json'
if (Test-Path -LiteralPath $fragmentConfigPath) {
    Write-ScriptMessage -Message "Collecting fragment dependency metrics..." -LogLevel Info
    
    # Level 1: Operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.populate.fragments] Collecting fragment dependency metrics from: $fragmentConfigPath"
    }
    
    try {
        $fragmentConfig = Read-JsonFile -Path $fragmentConfigPath -ErrorAction SilentlyContinue
        
        if ($fragmentConfig -and $fragmentConfig.Fragments) {
            $totalDependencies = 0
            $fragmentsWithDependencies = 0
            $maxDependencies = 0
            
            foreach ($frag in $fragmentConfig.Fragments) {
                if ($frag.Dependencies -and $frag.Dependencies.Count -gt 0) {
                    $fragmentsWithDependencies++
                    $totalDependencies += $frag.Dependencies.Count
                    if ($frag.Dependencies.Count -gt $maxDependencies) {
                        $maxDependencies = $frag.Dependencies.Count
                    }
                }
            }
            
            if ($fragmentsWithDependencies -gt 0) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'fragments_with_dependencies' -Value $fragmentsWithDependencies -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($totalDependencies -gt 0) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'total_fragment_dependencies' -Value $totalDependencies -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
                
                $avgDependencies = [Math]::Round($totalDependencies / $fragmentsWithDependencies, 2)
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'avg_fragment_dependencies' -Value $avgDependencies -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            if ($maxDependencies -gt 0) {
                if (& $safeAddMetric -MetricType 'code_metrics' -MetricName 'max_fragment_dependencies' -Value $maxDependencies -Unit 'count' -Metadata @{ Source = 'populate_performance_metrics' }) {
                    $metricsCount++
                }
            }
            
            Write-ScriptMessage -Message "Stored fragment dependency metrics in database" -LogLevel Info
            
            # Level 2: Summary
            if ($debugLevel -ge 2) {
                Write-Verbose "[metrics.populate.fragments] Fragment dependencies - Fragments with deps: $fragmentsWithDependencies, Total: $totalDependencies, Avg: $avgDependencies, Max: $maxDependencies"
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.populate.fragments' -Context @{
                config_path = $fragmentConfigPath
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to collect fragment dependency metrics: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Summary
$scriptStartTime = if (Get-Variable -Name 'scriptStartTime' -ErrorAction SilentlyContinue) { $scriptStartTime } else { Get-Date }
$totalDuration = ((Get-Date) - $scriptStartTime).TotalMilliseconds

Write-ScriptMessage -Message "`n=== Metrics Collection Summary ===" -LogLevel Info
Write-ScriptMessage -Message "Total metrics stored: $metricsCount" -LogLevel Info
Write-ScriptMessage -Message "Environment: $environment" -LogLevel Info

# Level 2: Timing summary
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.populate] Total execution time: $([Math]::Round($totalDuration, 1))ms"
}

# Level 3: Detailed performance breakdown
if ($debugLevel -ge 3) {
    Write-Host "  [metrics.populate] Performance summary - Total duration: $([Math]::Round($totalDuration, 1))ms, Metrics: $metricsCount, Failures: $failureCount" -ForegroundColor DarkGray
}

if ($IncludeCodeMetrics) {
    Write-ScriptMessage -Message "✓ Code metrics collected" -LogLevel Info
}
if ($IncludeStartupBenchmark) {
    Write-ScriptMessage -Message "✓ Startup benchmarks collected" -LogLevel Info
}
if ($IncludeDocumentationMetrics) {
    Write-ScriptMessage -Message "✓ Documentation metrics collected" -LogLevel Info
}
if (Test-Path -LiteralPath $lintReportPath) {
    Write-ScriptMessage -Message "✓ Lint metrics collected" -LogLevel Info
}
if (Test-Path -LiteralPath $testResultsPath) {
    Write-ScriptMessage -Message "✓ Test metrics collected" -LogLevel Info
}
if (Test-Path -LiteralPath (Join-Path $repoRoot '.git')) {
    Write-ScriptMessage -Message "✓ Git metrics collected" -LogLevel Info
}
if (Test-Path -LiteralPath (Join-Path $repoRoot 'docs' 'api' 'aliases')) {
    Write-ScriptMessage -Message "✓ Alias metrics collected" -LogLevel Info
}
if (Test-Path -LiteralPath $securityReportPath) {
    Write-ScriptMessage -Message "✓ Security metrics collected" -LogLevel Info
}
if (Test-Path -LiteralPath (Join-Path $repoRoot 'profile.d' 'fragment-config.json')) {
    Write-ScriptMessage -Message "✓ Fragment dependency metrics collected" -LogLevel Info
}

Write-ScriptMessage -Message "Performance metrics database population completed." -LogLevel Info

Exit-WithCode -ExitCode [ExitCode]::Success
Exit-WithCode -ExitCode [ExitCode]::Success
