# Quick library module coverage scanner
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
$libPath = Join-Path $repoRoot 'scripts' 'lib'
$testsRoot = Join-Path $repoRoot 'tests'
$testSupport = Join-Path $testsRoot 'TestSupport.ps1'
if (Test-Path $testSupport) { . $testSupport }

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

# Modules covered by umbrella test files when stem matching alone is insufficient.
$aggregateTestCoverage = @{
    'CodeMetrics'             = @('library-codeanalysis')
    'CodeSimilarityDetection' = @('library-codeanalysis')
    'AstParsing'              = @('library-codeanalysis')
    'CommentHelp'             = @('library-codeanalysis')
    'TestCoverage'            = @('library-test')
    'PerformanceMeasurement'  = @('library-performance')
    'PerformanceAggregation'  = @('library-performance')
    'PerformanceRegression'   = @('library-performance')
}

# Explicit glob patterns for modules whose test file stems do not normalize to the module name.
$explicitTestPatterns = @{
    'PathResolution' = @('library-path-resolution*', 'library-path.tests.ps1', 'library-path-extended.tests.ps1')
    'CommonEnums'    = @('library-common-enums*')
    'ErrorHandling'  = @('library-error-handling*')
    'PlatformPaths'  = @('library-platform-paths*')
    'MetricsSnapshot' = @('library-metrics-snapshot*')
    'ProfileFragmentLoader' = @('library-profile-fragment-loader*')
    'ProfileFragmentLoadingOrchestration' = @('library-profile-fragment-loading-orchestration*', 'library-profile-fragment-loader*')
    'FragmentLoading' = @('library-fragment-loading*')
    'Parallel' = @('library-parallel*')
}

$allTests = @(Get-ChildItem (Join-Path $testsRoot 'unit') -Filter 'library-*.tests.ps1' -Recurse -File)
$modules = @(Get-ChildItem $libPath -Filter '*.psm1' -Recurse -File)
$results = [System.Collections.Generic.List[object]]::new()

Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

foreach ($mod in $modules) {
    $stem = Get-NormalizedModuleStem -ModuleName $mod.BaseName
    $matched = @($allTests | Where-Object { (Get-NormalizedLibraryTestStem -TestFileBaseName $_.BaseName) -eq $stem })
    if ($matched.Count -eq 0 -and $explicitTestPatterns.ContainsKey($mod.BaseName)) {
        $extra = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        foreach ($pattern in $explicitTestPatterns[$mod.BaseName]) {
            foreach ($t in $allTests) {
                if ($t.BaseName -like $pattern) { $extra.Add($t) }
            }
        }
        $matched = @($extra | Select-Object -Unique)
    }
    if ($matched.Count -eq 0 -and $aggregateTestCoverage.ContainsKey($mod.BaseName)) {
        $extra = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        foreach ($prefix in $aggregateTestCoverage[$mod.BaseName]) {
            foreach ($t in $allTests) {
                if ($t.BaseName -like "$prefix*") { $extra.Add($t) }
            }
        }
        $matched = @($extra | Select-Object -Unique)
    }
    if ($matched.Count -eq 0) {
        Write-Host "SKIP $($mod.BaseName) - no tests" -ForegroundColor DarkGray
        continue
    }

    $config = New-PesterConfiguration
    $config.Run.Path = $matched.FullName
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = $mod.FullName
    $config.Output.Verbosity = 'None'
    $config.Run.PassThru = $true

    $r = Invoke-Pester -Configuration $config
    $cov = $r.CodeCoverage
    $pct = if ($cov.CoveragePercent) {
        [math]::Round($cov.CoveragePercent, 1)
    }
    elseif ($cov.CommandsAnalyzedCount -gt 0) {
        [math]::Round(($cov.CommandsExecutedCount / $cov.CommandsAnalyzedCount) * 100, 1)
    }
    else { 0 }

    $color = if ($pct -ge 80) { 'Green' } elseif ($pct -ge 60) { 'Yellow' } else { 'Red' }
    Write-Host ("{0,-30} {1,5}%  missed={2}/{3}  tests={4}" -f $mod.BaseName, $pct, $cov.CommandsMissedCount, $cov.CommandsAnalyzedCount, $matched.Count) -ForegroundColor $color
    $results.Add([pscustomobject]@{
            Module   = $mod.BaseName
            Path     = $mod.FullName
            Coverage = $pct
            Missed   = $cov.CommandsMissedCount
            Analyzed = $cov.CommandsAnalyzedCount
            Tests    = $matched.Count
        })
}

Write-Host ''
Write-Host 'Modules below 80% coverage:' -ForegroundColor Yellow
$results | Where-Object { $_.Coverage -lt 80 } | Sort-Object Coverage | Format-Table Module, Coverage, Missed, Analyzed, Tests -AutoSize
