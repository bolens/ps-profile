<#
scripts/utils/collect-code-metrics.ps1

.SYNOPSIS
    Collects code metrics for the PowerShell profile codebase.

.DESCRIPTION
    Analyzes PowerShell scripts and generates code metrics including:
    - Line counts
    - Function counts
    - Complexity metrics
    - Code quality statistics

.PARAMETER OutputPath
    Optional path to save metrics JSON file. Defaults to scripts/data/code-metrics.json

.PARAMETER Path
    Path to analyze. Defaults to repository root (scripts and profile.d directories).

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\collect-code-metrics.ps1

    Collects code metrics for the entire codebase.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\collect-code-metrics.ps1 -Path scripts/utils

    Collects code metrics for scripts/utils directory only.
#>

param(
    [string]$OutputPath = $null,

    [string]$Path = $null,

    [string]$CoverageXmlPath = $null,

    [switch]$IncludeQualityScore,

    [switch]$IncludeCodeSimilarity,

    [double]$SimilarityThreshold = 0.7
)

# Import shared utilities
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Collections' -ScriptPath $PSScriptRoot -DisableNameChecking
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.collect] Starting code metrics collection"
    Write-Verbose "[metrics.collect] Output path: $OutputPath, Path: $Path, Coverage XML path: $CoverageXmlPath"
    Write-Verbose "[metrics.collect] Include quality score: $IncludeQualityScore, Include code similarity: $IncludeCodeSimilarity"
}

# Determine paths to analyze
if ($Path) {
    $pathsToAnalyze = @($Path)
}
else {
    $pathsToAnalyze = @(
        Join-Path $repoRoot 'scripts'
        Join-Path $repoRoot 'profile.d'
    ) | Where-Object { Test-Path $_ }
}

Write-ScriptMessage -Message "Collecting code metrics..." -LogLevel Info

# Level 2: Path list details
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.collect] Paths to analyze: $($pathsToAnalyze -join ', ')"
}

# Collect metrics for each path sequentially (jobs can miss module context)
$allMetrics = [System.Collections.Generic.List[PSCustomObject]]::new()
$failedPaths = [System.Collections.Generic.List[string]]::new()
$collectStartTime = Get-Date
foreach ($path in $pathsToAnalyze) {
    # Level 1: Individual path analysis
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.collect] Analyzing path: $path"
    }
    
    Write-ScriptMessage -Message "Analyzing: $path" -LogLevel Info
    
    $pathStartTime = Get-Date
    try {
        $metrics = Get-CodeMetrics -Path $path -Recurse -ErrorAction Stop
        $pathDuration = ((Get-Date) - $pathStartTime).TotalMilliseconds
        
        if ($metrics) {
            $allMetrics.Add($metrics)
            
            # Level 2: Path analysis timing
            if ($debugLevel -ge 2) {
                Write-Verbose "[metrics.collect] Path $path analyzed in ${pathDuration}ms - Files: $($metrics.TotalFiles), Lines: $($metrics.TotalLines)"
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to collect metrics for path" -OperationName 'metrics.collection.path' -Context @{
                path = $path
            } -Code 'MetricsCollectionFailed'
        }
        else {
            Write-ScriptMessage -Message "Failed to collect metrics for path '$path': $($_.Exception.Message)" -IsWarning
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[metrics.collect] Path $path failed with error: $($_.Exception.Message)"
        }
        
        $failedPaths.Add($path)
    }
}

$collectDuration = ((Get-Date) - $collectStartTime).TotalMilliseconds

# Level 2: Overall collection timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.collect] Metrics collection completed in ${collectDuration}ms"
    Write-Verbose "[metrics.collect] Successful paths: $($pathsToAnalyze.Count - $failedPaths.Count), Failed paths: $($failedPaths.Count)"
}

if ($failedPaths.Count -gt 0) {
    if ($failedPaths.Count -gt 0) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Some paths failed during metrics collection" -OperationName 'metrics.collection.path' -Context @{
                failed_paths = $failedPaths -join ','
                failed_count = $failedPaths.Count
            } -Code 'MetricsCollectionPartialFailure'
        }
        else {
            Write-ScriptMessage -Message "Warning: Failed to collect metrics from $($failedPaths.Count) path(s): $($failedPaths -join ', ')" -IsWarning
        }
    }
}

# Aggregate metrics
$totalFiles = ($allMetrics | Measure-Object -Property TotalFiles -Sum).Sum
$totalLines = ($allMetrics | Measure-Object -Property TotalLines -Sum).Sum
$totalFunctions = ($allMetrics | Measure-Object -Property TotalFunctions -Sum).Sum
$totalComplexity = ($allMetrics | Measure-Object -Property TotalComplexity -Sum).Sum
$totalDuplicates = ($allMetrics | Measure-Object -Property DuplicateFunctions -Sum).Sum

# Collect test coverage if coverage file is provided
$testCoverage = $null
if ($CoverageXmlPath) {
    if (Test-Path -Path $CoverageXmlPath) {
        Write-ScriptMessage -Message "Collecting test coverage metrics..." -LogLevel Info
        try {
            $testCoverage = Get-TestCoverage -CoverageXmlPath $CoverageXmlPath -ErrorAction Stop
            if ($testCoverage) {
                $coveragePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $testCoverage.CoveragePercent -Format 'N2'
                }
                else {
                    $testCoverage.CoveragePercent.ToString("N2")
                }
                Write-ScriptMessage -Message "  Coverage: ${coveragePercentStr}%" -LogLevel Info
            }
        }
        catch {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to collect test coverage" -OperationName 'metrics.collection.coverage' -Context @{
                    coverage_file = $CoverageXmlPath
                } -Code 'CoverageCollectionFailed'
            }
            else {
                Write-ScriptMessage -Message "Failed to collect test coverage from '$CoverageXmlPath': $($_.Exception.Message)" -IsWarning
            }
        }
    }
    else {
        Write-ScriptMessage -Message "Coverage file not found: $CoverageXmlPath" -IsWarning
    }
}
else {
    # Try to find coverage.xml in common locations
    $possibleCoveragePaths = @(
        Join-Path $repoRoot 'coverage.xml'
        Join-Path $repoRoot 'scripts' 'data' 'coverage.xml'
    )

    foreach ($coveragePath in $possibleCoveragePaths) {
        if (Test-Path -Path $coveragePath) {
            Write-ScriptMessage -Message "Found coverage file: $coveragePath" -LogLevel Info
            try {
                $testCoverage = Get-TestCoverage -CoverageXmlPath $coveragePath -ErrorAction Stop
                if ($testCoverage) {
                    $coveragePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                        Format-LocaleNumber $testCoverage.CoveragePercent -Format 'N2'
                    }
                    else {
                        $testCoverage.CoveragePercent.ToString("N2")
                    }
                    Write-ScriptMessage -Message "  Coverage: ${coveragePercentStr}%" -LogLevel Info
                    break
                }
            }
            catch {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to collect test coverage" -OperationName 'metrics.collection.coverage' -Context @{
                        coverage_file = $coveragePath
                    } -Code 'CoverageCollectionFailed'
                }
                else {
                    Write-ScriptMessage -Message "Failed to collect test coverage from '$coveragePath': $($_.Exception.Message)" -IsWarning
                }
                # Continue to next possible path
            }
        }
    }
}

# Import PathUtilities module for path normalization
Import-LibModule -ModuleName 'PathUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking

# Normalize paths to be relative to repo root to avoid personal absolute paths
# Use PathUtilities module if available
if (Get-Command ConvertTo-RepoRelativePath -ErrorAction SilentlyContinue) {
    $toRelativePath = {
        param($path)
        return ConvertTo-RepoRelativePath -Path $path -RepoRoot $repoRoot
    }
}
else {
    # Fallback to manual calculation
    $toRelativePath = {
        param($path)
        if ([string]::IsNullOrEmpty($path)) { return $path }
        try {
            $resolved = Resolve-Path -LiteralPath $path -ErrorAction Stop
            $relative = [System.IO.Path]::GetRelativePath($repoRoot, $resolved.ProviderPath)
            if (-not [string]::IsNullOrWhiteSpace($relative)) {
                return $relative
            }
        }
        catch {
            # Fall back to input path if it cannot be resolved
        }
        return $path
    }
}

foreach ($pathMetric in $allMetrics) {
    if ($pathMetric.PSObject.Properties['Path']) {
        $pathMetric.Path = & $toRelativePath $pathMetric.Path
    }

    if ($pathMetric.FileMetrics) {
        foreach ($fileMetric in $pathMetric.FileMetrics) {
            $fileMetric.Path = & $toRelativePath $fileMetric.Path
        }
    }

    if ($pathMetric.DuplicateFunctionDetails) {
        foreach ($dup in $pathMetric.DuplicateFunctionDetails) {
            if ($dup.PSObject.Properties['Path']) {
                $dup.Path = & $toRelativePath $dup.Path
            }
        }
    }
}

if ($testCoverage -and $testCoverage.FileCoverage) {
    foreach ($fileCoverage in $testCoverage.FileCoverage) {
        $fileCoverage.Path = & $toRelativePath $fileCoverage.Path
    }
}

# Calculate code quality score (enabled by default, can be disabled with -IncludeQualityScore:$false)
$qualityScore = $null
if ($IncludeQualityScore -or -not $PSBoundParameters.ContainsKey('IncludeQualityScore')) {
    Write-ScriptMessage -Message "Calculating code quality score..." -LogLevel Info
    $aggregatedMetrics = [PSCustomObject]@{
        TotalFiles               = $totalFiles
        TotalLines               = $totalLines
        TotalFunctions           = $totalFunctions
        TotalComplexity          = $totalComplexity
        DuplicateFunctions       = $totalDuplicates
        AverageLinesPerFile      = if ($totalFiles -gt 0) { [math]::Round($totalLines / $totalFiles, 2) } else { 0 }
        AverageFunctionsPerFile  = if ($totalFiles -gt 0) { [math]::Round($totalFunctions / $totalFiles, 2) } else { 0 }
        AverageComplexityPerFile = if ($totalFiles -gt 0) { [math]::Round($totalComplexity / $totalFiles, 2) } else { 0 }
    }
    try {
        Import-LibModule -ModuleName 'CodeQualityScore' -ScriptPath $PSScriptRoot -DisableNameChecking
        $qualityScore = Get-CodeQualityScore -CodeMetrics $aggregatedMetrics -TestCoverage $testCoverage
        Write-ScriptMessage -Message "  Quality Score: $($qualityScore.Score)/100" -LogLevel Info
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to calculate quality score" -OperationName 'metrics.collection.quality-score' -Context @{} -Code 'QualityScoreCalculationFailed'
        }
        else {
            Write-ScriptMessage -Message "  Failed to calculate quality score: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Detect code similarity (enabled by default, can be disabled with -IncludeCodeSimilarity:$false)
$codeSimilarity = $null
if ($IncludeCodeSimilarity -or -not $PSBoundParameters.ContainsKey('IncludeCodeSimilarity')) {
    Write-ScriptMessage -Message "Detecting code similarity..." -LogLevel Info
    try {
        Import-LibModule -ModuleName 'CodeSimilarityDetection' -ScriptPath $PSScriptRoot -DisableNameChecking
        $similarityResults = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($path in $pathsToAnalyze) {
            $similar = Get-CodeSimilarity -Path $path -Recurse -MinSimilarity $SimilarityThreshold
            if ($similar) {
                $similarityResults.AddRange($similar)
            }
        }
        $codeSimilarity = $similarityResults.ToArray()
        foreach ($similar in $codeSimilarity) {
            if ($similar.PSObject.Properties['File1']) {
                $similar.File1 = & $toRelativePath $similar.File1
            }
            if ($similar.PSObject.Properties['File2']) {
                $similar.File2 = & $toRelativePath $similar.File2
            }
        }
        Write-ScriptMessage -Message "  Found $($codeSimilarity.Count) similar code blocks" -LogLevel Info
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to detect code similarity" -OperationName 'metrics.collection.similarity' -Context @{} -Code 'SimilarityDetectionFailed'
        }
        else {
            Write-ScriptMessage -Message "  Failed to detect code similarity: $($_.Exception.Message)" -IsWarning
        }
    }
}

$summary = [PSCustomObject]@{
    Timestamp                = [DateTime]::UtcNow.ToString('o')
    TotalFiles               = $totalFiles
    TotalLines               = $totalLines
    TotalFunctions           = $totalFunctions
    TotalComplexity          = $totalComplexity
    DuplicateFunctions       = $totalDuplicates
    AverageLinesPerFile      = if ($totalFiles -gt 0) { [math]::Round($totalLines / $totalFiles, 2) } else { 0 }
    AverageFunctionsPerFile  = if ($totalFiles -gt 0) { [math]::Round($totalFunctions / $totalFiles, 2) } else { 0 }
    AverageComplexityPerFile = if ($totalFiles -gt 0) { [math]::Round($totalComplexity / $totalFiles, 2) } else { 0 }
    PathMetrics              = $allMetrics.ToArray()
    TestCoverage             = $testCoverage
    QualityScore             = $qualityScore
    CodeSimilarity           = $codeSimilarity
}

# Display summary
Write-ScriptMessage -Message "`nCode Metrics Summary:" -LogLevel Info
Write-ScriptMessage -Message "  Total Files: $totalFiles" -LogLevel Info
Write-ScriptMessage -Message "  Total Lines: $totalLines" -LogLevel Info
Write-ScriptMessage -Message "  Total Functions: $totalFunctions" -LogLevel Info
Write-ScriptMessage -Message "  Total Complexity: $totalComplexity" -LogLevel Info
$avgLinesStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([Math]::Round($summary.AverageLinesPerFile, 2)) -Format 'N2'
}
else {
    [Math]::Round($summary.AverageLinesPerFile, 2).ToString("N2")
}
$avgFunctionsStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([Math]::Round($summary.AverageFunctionsPerFile, 2)) -Format 'N2'
}
else {
    [Math]::Round($summary.AverageFunctionsPerFile, 2).ToString("N2")
}
$avgComplexityStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([Math]::Round($summary.AverageComplexityPerFile, 2)) -Format 'N2'
}
else {
    [Math]::Round($summary.AverageComplexityPerFile, 2).ToString("N2")
}
Write-ScriptMessage -Message "  Avg Lines/File: $avgLinesStr" -LogLevel Info
Write-ScriptMessage -Message "  Avg Functions/File: $avgFunctionsStr" -LogLevel Info
Write-ScriptMessage -Message "  Avg Complexity/File: $avgComplexityStr" -LogLevel Info

if ($summary.DuplicateFunctions -gt 0) {
    Write-ScriptMessage -Message "  Duplicate Functions: $($summary.DuplicateFunctions)" -IsWarning
    Write-ScriptMessage -Message "`nDuplicate Function Details:" -LogLevel Info
    foreach ($pathMetric in $allMetrics) {
        if ($pathMetric.DuplicateFunctionDetails -and $pathMetric.DuplicateFunctionDetails.Count -gt 0) {
            foreach ($dup in $pathMetric.DuplicateFunctionDetails) {
                Write-ScriptMessage -Message "    - $($dup.FunctionName) in $($dup.File)" -IsWarning
            }
        }
    }
}

if ($testCoverage) {
    Write-ScriptMessage -Message "`nTest Coverage:" -LogLevel Info
    $coveragePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        Format-LocaleNumber $testCoverage.CoveragePercent -Format 'N2'
    }
    else {
        $testCoverage.CoveragePercent.ToString("N2")
    }
    Write-ScriptMessage -Message "  Overall Coverage: ${coveragePercentStr}%" -LogLevel Info
    Write-ScriptMessage -Message "  Covered Lines: $($testCoverage.CoveredLines) / $($testCoverage.TotalLines)" -LogLevel Info
}

if ($qualityScore) {
    Write-ScriptMessage -Message "`nCode Quality Score: $($qualityScore.Score)/100" -LogLevel Info
    Write-ScriptMessage -Message "  Component Scores:" -LogLevel Info
    Write-ScriptMessage -Message "    Complexity: $($qualityScore.ComponentScores.Complexity)" -LogLevel Info
    Write-ScriptMessage -Message "    Duplicates: $($qualityScore.ComponentScores.Duplicates)" -LogLevel Info
    Write-ScriptMessage -Message "    Coverage: $($qualityScore.ComponentScores.Coverage)" -LogLevel Info
    Write-ScriptMessage -Message "    File Size: $($qualityScore.ComponentScores.FileSize)" -LogLevel Info
    Write-ScriptMessage -Message "    Function Density: $($qualityScore.ComponentScores.FunctionDensity)" -LogLevel Info
}

if ($codeSimilarity -and $codeSimilarity.Count -gt 0) {
    Write-ScriptMessage -Message "`nCode Similarity Detected:" -IsWarning
    $topSimilar = $codeSimilarity | Select-Object -First 5
    foreach ($similar in $topSimilar) {
        $similarityPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
            Format-LocaleNumber $similar.SimilarityPercent -Format 'N2'
        }
        else {
            $similar.SimilarityPercent.ToString("N2")
        }
        Write-ScriptMessage -Message "  $($similar.File1) <-> $($similar.File2): ${similarityPercentStr}% similar" -IsWarning
    }
    if ($codeSimilarity.Count -gt 5) {
        Write-ScriptMessage -Message "  ... and $($codeSimilarity.Count - 5) more similar blocks" -IsWarning
    }
}

# Save to file
if (-not $OutputPath) {
    $dataDir = Join-Path $repoRoot 'scripts' 'data'
    Ensure-DirectoryExists -Path $dataDir
    $OutputPath = Join-Path $dataDir 'code-metrics.json'
}

try {
    Write-JsonFile -Path $OutputPath -InputObject $summary -Depth 10 -EnsureDirectory -ErrorAction Stop
    Write-ScriptMessage -Message "`nMetrics saved to: $OutputPath" -LogLevel Info
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'metrics.collection.save' -Context @{
            output_path = $OutputPath
            metrics_collected = $allMetrics.Count -gt 0
        }
    }
    else {
        Write-ScriptMessage -Message "Failed to save metrics to '$OutputPath': $($_.Exception.Message)" -IsError
    }
    # Still exit with success if we collected metrics, but warn about save failure
    if ($allMetrics.Count -gt 0) {
        Write-ScriptMessage -Message "Metrics were collected but could not be saved. Consider retrying with a different output path." -IsWarning
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to save metrics file"
    }
    else {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to collect and save metrics" -ErrorRecord $_
    }
}

Exit-WithCode -ExitCode [ExitCode]::Success






