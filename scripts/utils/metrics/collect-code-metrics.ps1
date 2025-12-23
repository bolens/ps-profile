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
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
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

# Collect metrics for each path sequentially (jobs can miss module context)
$allMetrics = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($path in $pathsToAnalyze) {
    Write-ScriptMessage -Message "Analyzing: $path" -LogLevel Info
    $metrics = Get-CodeMetrics -Path $path -Recurse
    $allMetrics.Add($metrics)
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
        $testCoverage = Get-TestCoverage -CoverageXmlPath $CoverageXmlPath
        $coveragePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
            Format-LocaleNumber $testCoverage.CoveragePercent -Format 'N2'
        }
        else {
            $testCoverage.CoveragePercent.ToString("N2")
        }
        Write-ScriptMessage -Message "  Coverage: ${coveragePercentStr}%" -LogLevel Info
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
            $testCoverage = Get-TestCoverage -CoverageXmlPath $coveragePath
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
        Write-ScriptMessage -Message "  Failed to calculate quality score: $($_.Exception.Message)" -IsWarning
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
        Write-ScriptMessage -Message "  Failed to detect code similarity: $($_.Exception.Message)" -IsWarning
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
    Write-JsonFile -Path $OutputPath -InputObject $summary -Depth 10 -EnsureDirectory
    Write-ScriptMessage -Message "`nMetrics saved to: $OutputPath" -LogLevel Info
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to save metrics: $($_.Exception.Message)" -ErrorRecord $_
}

Exit-WithCode -ExitCode $EXIT_SUCCESS






