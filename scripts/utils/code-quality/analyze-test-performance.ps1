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
    [TestSuite]$Suite = [TestSuite]::All,

    [ValidateRange(1, 1000)]
    [int]$TopN = 20,

    [string]$OutputPath
)

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
try {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop -Global
    # Import CommonEnums for TestSuite enum
    $commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'core' 'CommonEnums.psm1'
    if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
        Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'test.performance.import-modules' -Context @{
            module_import_path = $moduleImportPath
        }
    }
    else {
        Write-Host "Failed to import required modules: $_" -ForegroundColor Red
    }
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
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
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'test.performance.get-repo-root' -Context @{
            script_path = $PSScriptRoot
        }
    }
    else {
        Write-Host "Failed to get repository root: $_" -ForegroundColor Red
    }
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
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
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'test.performance.import-discovery-modules' -Context @{
            modules_path = $modulesPath
        }
    }
    else {
        Write-Host "Failed to import test discovery modules: $_" -ForegroundColor Red
    }
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
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
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'test.performance.import-pester' -Context @{
            minimum_version = '5.0.0'
        }
    }
    else {
        Write-Host "Failed to import Pester: $_" -ForegroundColor Red
    }
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
    }
    else {
        Write-Error "Failed to import Pester: $($_.Exception.Message)" -ErrorAction Stop
    }
}

# Convert enum to string
$suiteString = $Suite.ToString()

Write-Host "Analyzing test performance for suite: $suiteString" -ForegroundColor Cyan
Write-Host ""

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[test.performance] Starting analysis for suite: $suiteString"
    Write-Verbose "[test.performance] Top N slowest tests to report: $TopN"
}

# Get test paths
$testPaths = Get-TestPaths -Suite $suiteString -TestFile $null -RepoRoot $repoRoot

if ($testPaths.Count -eq 0) {
    Write-Host "No test paths found for suite: $suiteString" -ForegroundColor Yellow
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "No test paths found for suite: $suiteString"
}

Write-Host "Found $($testPaths.Count) test file(s)" -ForegroundColor Green
Write-Host ""

# Level 2: Detailed operation context
if ($debugLevel -ge 2) {
    Write-Verbose "[test.performance] Test paths: $($testPaths -join ', ')"
}

# Create configuration for detailed timing
$config = New-PesterConfiguration
$config.Run.PassThru = $true
$config.Run.Exit = $false
$config.Output.Verbosity = 'None'  # Minimal output for performance
$config.Run.Path = $testPaths

# Track timing
$startTime = Get-Date
Write-Host "Running tests with timing analysis..." -ForegroundColor Cyan

# Level 1: Operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[test.performance] Executing Pester tests with timing analysis"
}

# Run tests
$result = Invoke-Pester -Configuration $config

$endTime = Get-Date
$totalDuration = $endTime - $startTime
$durationMs = $totalDuration.TotalMilliseconds

# Level 2: Timing information
if ($debugLevel -ge 2) {
    Write-Verbose "[test.performance] Test execution completed in ${durationMs}ms"
    Write-Verbose "[test.performance] Total tests: $($result.TotalCount), Passed: $($result.PassedCount), Failed: $($result.FailedCount)"
}

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

# Level 1: Analysis start
if ($debugLevel -ge 1) {
    Write-Verbose "[test.performance] Analyzing test results"
}

# Analyze test results
$testTimings = [System.Collections.Generic.List[PSCustomObject]]::new()
$failedAnalyses = [System.Collections.Generic.List[string]]::new()

foreach ($testResult in $result.Tests) {
    try {
        $testTimings.Add([PSCustomObject]@{
            Name       = $testResult.ExpandedName
            Duration   = $testResult.Duration
            DurationMs = $testResult.Duration.TotalMilliseconds
            File       = $testResult.Block.Path
            Status     = $testResult.Result
        })
    }
    catch {
        $testName = if ($testResult.ExpandedName) { $testResult.ExpandedName } else { 'Unknown' }
        $failedAnalyses.Add($testName)
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to analyze test result" -OperationName 'test.performance.analyze-result' -Context @{
                test_name = $testName
            } -Code 'TestAnalysisFailed'
        }
    }
}

if ($failedAnalyses.Count -gt 0) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Some test results could not be analyzed" -OperationName 'test.performance.analyze' -Context @{
            failed_tests = $failedAnalyses -join ','
            failed_count = $failedAnalyses.Count
            total_tests = $result.Tests.Count
        } -Code 'TestAnalysisPartialFailure'
    }
}

# Level 2: Analysis details
if ($debugLevel -ge 2) {
    Write-Verbose "[test.performance] Processed $($testTimings.Count) test results, $($failedAnalyses.Count) failed analyses"
}

# Sort by duration (slowest first)
$slowTests = $testTimings | Sort-Object -Property DurationMs -Descending | Select-Object -First $TopN

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgDuration = if ($testTimings.Count -gt 0) { ($testTimings | Measure-Object -Property DurationMs -Average).Average } else { 0 }
    $maxDuration = if ($testTimings.Count -gt 0) { ($testTimings | Measure-Object -Property DurationMs -Maximum).Maximum } else { 0 }
    Write-Host "  [test.performance] Analysis metrics - Avg: ${avgDuration}ms, Max: ${maxDuration}ms, Total: $($testTimings.Count) tests" -ForegroundColor DarkGray
}

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
Suite: $suiteString
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

# Level 1: Report generation
if ($debugLevel -ge 1) {
    Write-Verbose "[test.performance] Generating performance report"
}

# Output report
if ($OutputPath) {
    try {
        $report | Out-File -FilePath $OutputPath -Encoding UTF8 -ErrorAction Stop
        Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
        if ($debugLevel -ge 2) {
            Write-Verbose "[test.performance] Report saved to: $OutputPath"
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'test.performance.save-report' -Context @{
                output_path = $OutputPath
            }
        }
        else {
            Write-Host "Failed to save report: $($_.Exception.Message)" -ForegroundColor Red
        }
        # Still output to console as fallback
        Write-Host $report
    }
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

