<#
.SYNOPSIS
    Reports library modules under scripts/lib that lack matching unit tests.

.DESCRIPTION
    Scans all .psm1 files under scripts/lib recursively and compares them to
    tests/unit/library-*.tests.ps1 naming conventions (including -extended and
    -structure-extended suffixes).
.PARAMETER ModuleName
    Module name used for test discovery.
.PARAMETER LibraryTestFiles
    Existing library test files used for matching.
.EXAMPLE
    Test-HasLibraryTest

#>ARAMETER TestFileBaseName
    TestFileBase file name without extension.
.EXAMPLE
    Get-NormalizedLibraryTestStem

#>ARAMETER ModuleName
    Module name used for test discovery.
.EXAMPLE
    Get-NormalizedModuleStem

#>

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
$libPath = Join-Path $repoRoot 'scripts' 'lib'
$testPath = Join-Path $repoRoot 'tests' 'unit'

function Get-NormalizedModuleStem {
    param([string]$ModuleName)

    return ($ModuleName -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
}

function Get-NormalizedLibraryTestStem {
    param([string]$TestFileBaseName)

    $stem = $TestFileBaseName -replace '\.tests$', ''
    $stem = $stem -replace '^library-', ''
    $stem = $stem -replace '-structure-extended$', ''
    $stem = $stem -replace '-extended$', ''
    return ($stem -replace '[^a-z0-9]', '').ToLowerInvariant()
}

function Test-HasLibraryTest {
    param(
        [string]$ModuleName,
        [System.IO.FileInfo[]]$LibraryTestFiles
    )

    $moduleStem = Get-NormalizedModuleStem -ModuleName $ModuleName

    foreach ($testFile in $LibraryTestFiles) {
        $testStem = Get-NormalizedLibraryTestStem -TestFileBaseName $testFile.BaseName
        if ($testStem -eq $moduleStem) {
            return $true
        }
    }

    return $false
}

# Modules covered by umbrella / aggregate test files rather than a 1:1 name match.
$aggregateTestCoverage = @{
    'CodeMetrics'             = @('library-codeanalysis')
    'CodeSimilarityDetection' = @('library-codeanalysis')
    'AstParsing'              = @('library-codeanalysis')
    'CommentHelp'             = @('library-codeanalysis')
    'TestCoverage'            = @('library-codeanalysis')
    'PerformanceMeasurement'  = @('library-performance')
    'PerformanceAggregation'  = @('library-performance')
    'PerformanceRegression'     = @('library-performance')
    'MetricsSnapshot'         = @('library-metrics')
    'MetricsHistory'          = @('library-metrics')
    'MetricsTrendAnalysis'    = @('library-metrics')
    'CodeQualityScore'        = @('library-metrics')
}

$modules = @(Get-ChildItem -Path $libPath -Filter '*.psm1' -Recurse -File |
    ForEach-Object { $_.BaseName } |
    Sort-Object -Unique)

$testFiles = @(Get-ChildItem -Path $testPath -Filter 'library-*.tests.ps1' -File)

$testedModules = [System.Collections.Generic.List[string]]::new()
foreach ($moduleName in $modules) {
    if (Test-HasLibraryTest -ModuleName $moduleName -LibraryTestFiles $testFiles) {
        $testedModules.Add($moduleName)
        continue
    }

    if ($aggregateTestCoverage.ContainsKey($moduleName)) {
        $covered = $false
        foreach ($aggregatePrefix in $aggregateTestCoverage[$moduleName]) {
            if ($testFiles.BaseName -contains "$aggregatePrefix.tests" -or
                ($testFiles.BaseName | Where-Object { $_ -like "$aggregatePrefix*" }).Count -gt 0) {
                $covered = $true
                break
            }
        }

        if ($covered) {
            $testedModules.Add($moduleName)
        }
    }
}

$testedModules = $testedModules | Select-Object -Unique
$missing = $modules | Where-Object { $testedModules -notcontains $_ }

Write-Host "Total modules: $($modules.Count)"
Write-Host "Total test files: $($testFiles.Count)"
Write-Host "Modules with tests: $($testedModules.Count)"
Write-Host "`nMissing tests for:"
if ($missing.Count -eq 0) {
    Write-Host '  (none)'
}
else {
    $missing | Sort-Object | ForEach-Object { Write-Host "  - $_" }
}

if ($missing.Count -gt 0) {
    exit 1
}

exit 0
