<#
scripts/utils/code-quality/analyze-test-performance.ps1

.SYNOPSIS
    Analyzes test execution performance to identify slow tests.

.DESCRIPTION
    Runs tests with timing information to identify which tests are taking
    the longest to execute. Helps optimize test suite performance.

.PARAMETER Suite
    Test suite to analyze. Valid values: All, Unit, Integration, Performance.
    Defaults to All.

.PARAMETER TopN
    Number of slowest tests to report. Defaults to 20.

.PARAMETER OutputPath
    Path to save the analysis report. If not specified, outputs to console.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/analyze-test-performance.ps1 -Suite Unit

    Analyzes unit test performance and reports the 20 slowest tests.
#>

param(
    [ValidateSet('All', 'Unit', 'Integration', 'Performance')]
    [string]$Suite = 'All',

    [int]$TopN = 20,

    [string]$OutputPath
)

# Import shared utilities
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
try {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop -Global
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
}
catch {
    Write-Host "Failed to import required modules: $_" -ForegroundColor Red
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
    else {
        Write-Error "Failed to import required modules: $($_.Exception.Message)" -ErrorAction Stop
    }
}

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $testsDir = Join-Path $repoRoot 'tests'
}
catch {
    Write-Host "Failed to get repository root: $_" -ForegroundColor Red
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
    else {
        Write-Error "Failed to get repository root: $($_.Exception.Message)" -ErrorAction Stop
    }
}

# Import test discovery modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
try {
    Import-Module (Join-Path $modulesPath 'TestPathResolution.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestPathUtilities.psm1') -DisableNameChecking -ErrorAction Stop
}
catch {
    Write-Host "Failed to import test discovery modules: $_" -ForegroundColor Red
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
    else {
        Write-Error "Failed to import test discovery modules: $($_.Exception.Message)" -ErrorAction Stop
    }
}

# Ensure Pester is available
try {
    Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Ensure-ModuleAvailable -ModuleName 'Pester'
    Import-Module Pester -MinimumVersion 5.0.0 -Force -ErrorAction Stop
}
catch {
    Write-Host "Failed to import Pester: $_" -ForegroundColor Red
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
    else {
        Write-Error "Failed to import Pester: $($_.Exception.Message)" -ErrorAction Stop
    }
}

Write-Host "Analyzing test performance for suite: $Suite" -ForegroundColor Cyan
Write-Host ""

# Get test paths
$testPaths = Get-TestPaths -Suite $Suite -TestFile $null -RepoRoot $repoRoot

if ($testPaths.Count -eq 0) {
    Write-Host "No test paths found for suite: $Suite" -ForegroundColor Yellow
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "No test paths found for suite: $Suite"
    }
    else {
        return
    }
}

Write-Host "Found $($testPaths.Count) test file(s)" -ForegroundColor Green
Write-Host ""

# Create configuration for detailed timing
$config = New-PesterConfiguration
$config.Run.PassThru = $true
$config.Run.Exit = $false
$config.Output.Verbosity = 'None'  # Minimal output for performance
$config.Run.Path = $testPaths

# Track timing
$startTime = Get-Date
Write-Host "Running tests with timing analysis..." -ForegroundColor Cyan

# Run tests
$result = Invoke-Pester -Configuration $config

$endTime = Get-Date
$totalDuration = $endTime - $startTime

Write-Host ""

# Use locale-aware number formatting for duration
$durationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([Math]::Round($totalDuration.TotalSeconds, 2)) -Format 'N2'
}
else {
    [Math]::Round($totalDuration.TotalSeconds, 2).ToString("N2")
}
Write-Host "Test execution completed in ${durationStr} seconds" -ForegroundColor Green
Write-Host ""

# Analyze test results
$testTimings = @()

foreach ($testResult in $result.Tests) {
    $testTimings += [PSCustomObject]@{
        Name       = $testResult.ExpandedName
        Duration   = $testResult.Duration
        DurationMs = $testResult.Duration.TotalMilliseconds
        File       = $testResult.Block.Path
        Status     = $testResult.Result
    }
}

# Sort by duration (slowest first)
$slowTests = $testTimings | Sort-Object -Property DurationMs -Descending | Select-Object -First $TopN

# Group by file to identify slow test files
$fileTimings = $testTimings | Group-Object -Property File | ForEach-Object {
    $fileDuration = ($_.Group | Measure-Object -Property DurationMs -Sum).Sum
    $testCount = $_.Count
    [PSCustomObject]@{
        File        = $_.Name
        DurationMs  = $fileDuration
        Duration    = [TimeSpan]::FromMilliseconds($fileDuration)
        TestCount   = $testCount
        AvgDuration = $fileDuration / $testCount
    }
} | Sort-Object -Property DurationMs -Descending | Select-Object -First $TopN

# Generate report
# Use locale-aware date formatting for user-facing report
$generatedDate = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
    Format-LocaleDate (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
}
else {
    (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

$report = @"
# Test Performance Analysis Report

Generated: $generatedDate
Suite: $Suite
Total Tests: $($result.TotalCount)
Passed: $($result.PassedCount)
Failed: $($result.FailedCount)
Skipped: $($result.SkippedCount)
Total Duration: $(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([Math]::Round($totalDuration.TotalSeconds, 2)) -Format 'N2'
} else {
    [Math]::Round($totalDuration.TotalSeconds, 2).ToString("N2")
}) seconds

## Top $TopN Slowest Individual Tests

"@

$rank = 1
foreach ($test in $slowTests) {
    $report += @"
$rank. **$($test.Name)**
   - Duration: $(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        Format-LocaleNumber ([Math]::Round($test.DurationMs, 2)) -Format 'N2'
    } else {
        [Math]::Round($test.DurationMs, 2).ToString("N2")
    }) ms ($(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        Format-LocaleNumber ([Math]::Round($test.Duration.TotalSeconds, 2)) -Format 'N2'
    } else {
        [Math]::Round($test.Duration.TotalSeconds, 2).ToString("N2")
    }) s)
   - File: $($test.File)
   - Status: $($test.Status)

"@
    $rank++
}

$report += @"

## Top $TopN Slowest Test Files

"@

$rank = 1
foreach ($file in $fileTimings) {
    $report += @"
$rank. **$($file.File)**
   - Total Duration: $(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        Format-LocaleNumber ([Math]::Round($file.DurationMs, 2)) -Format 'N2'
    } else {
        [Math]::Round($file.DurationMs, 2).ToString("N2")
    }) ms ($(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        Format-LocaleNumber ([Math]::Round($file.Duration.TotalSeconds, 2)) -Format 'N2'
    } else {
        [Math]::Round($file.Duration.TotalSeconds, 2).ToString("N2")
    }) s)
   - Test Count: $($file.TestCount)
   - Average per Test: $(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        Format-LocaleNumber ([Math]::Round($file.AvgDuration, 2)) -Format 'N2'
    } else {
        [Math]::Round($file.AvgDuration, 2).ToString("N2")
    }) ms

"@
    $rank++
}

$report += @"

## Recommendations

1. **Focus on slowest test files first** - Optimizing these will have the biggest impact
2. **Look for common patterns** - Tests with similar slowness may share bottlenecks
3. **Consider parallel execution** - Tests in slow files may benefit from parallelization
4. **Review BeforeAll/AfterAll blocks** - Setup/teardown overhead can accumulate
5. **Check for external dependencies** - Network calls, file I/O, or process spawning slow tests

"@

# Output report
if ($OutputPath) {
    $report | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
}
else {
    Write-Host $report
}

# Also output summary to console
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan

# Use locale-aware number formatting
$slowestTestMs = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([Math]::Round($slowTests[0].DurationMs, 2)) -Format 'N2'
}
else {
    [Math]::Round($slowTests[0].DurationMs, 2).ToString("N2")
}
$slowestFileMs = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([Math]::Round($fileTimings[0].DurationMs, 2)) -Format 'N2'
}
else {
    [Math]::Round($fileTimings[0].DurationMs, 2).ToString("N2")
}
Write-Host "Slowest test: $($slowTests[0].Name) (${slowestTestMs} ms)" -ForegroundColor Yellow
Write-Host "Slowest file: $($fileTimings[0].File) (${slowestFileMs} ms total)" -ForegroundColor Yellow
Write-Host ""

