<#
scripts/utils/run-pester.ps1

.SYNOPSIS
    Runs Pester tests for the PowerShell profile with comprehensive options including
    retry logic, performance monitoring, environment health checks, and advanced reporting.

.DESCRIPTION
    Ensures Pester is available and runs the test suite in this repository with robust
    configuration options. Supports filtering, parallel execution, code coverage,
    output formatting, retry logic, performance tracking, environment validation,
    and detailed analysis and reporting.

.PARAMETER TestFile
    Optional path to a specific test file or directory to run. If not specified,
    runs all tests in the tests directory. Supports wildcards and relative paths.

.PARAMETER Suite
    The test suite to run. Valid values are All, Unit, Integration, or Performance.
    Defaults to All. When TestFile is specified, this parameter is ignored.

.PARAMETER TestName
    Optional filter for test names. Supports wildcards and multiple patterns
    separated by " or ", commas, or semicolons. Examples: "*Edit-Profile*", "*Backup* or *Restore*".

.PARAMETER IncludeTag
    Include only tests with the specified tags. Can be specified multiple times.
    Use with -ExcludeTag for complex filtering.

.PARAMETER ExcludeTag
    Exclude tests with the specified tags. Can be specified multiple times.
    Use with -IncludeTag for complex filtering.

.PARAMETER OutputFormat
    Controls the verbosity of test output. Valid values are:
    - Normal: Standard test output with summary
    - Detailed: Verbose output with individual test results
    - Minimal: Minimal output, only failures and summary
    - None: No output except final results object
    Defaults to Detailed.

.PARAMETER OutputPath
    Path to save test results. Supports .xml, .json, and .nunit formats.
    When specified, results are saved in addition to console output.

.PARAMETER Coverage
    If specified, enables code coverage reporting for profile.d directory.

.PARAMETER CodeCoverageOutputFormat
    Format for code coverage output. Valid values are JaCoCo, CoverageGutters, or Cobertura.
    Defaults to JaCoCo. Requires -Coverage to be specified.

.PARAMETER MinimumCoverage
    Minimum code coverage percentage required (0-100). If coverage falls below this
    threshold, the script exits with an error. Requires -Coverage to be specified.

.PARAMETER ShowCoverageSummary
    Display code coverage summary even when -Coverage is not specified.
    Useful for quick coverage checks without full reporting.

.PARAMETER Parallel
    Run tests in parallel for improved performance. Specify the maximum number
    of parallel threads (1-16). Defaults to number of logical processors if just
    -Parallel is specified without a value.

.PARAMETER Randomize
    Run tests in random order to detect order dependencies.

.PARAMETER Repeat
    Run the test suite multiple times. Useful for detecting flaky tests.
    Specify the number of repetitions (1-100). Defaults to 1.

.PARAMETER Timeout
    Maximum time in seconds to allow tests to run. If exceeded, tests are aborted.
    Default is no timeout.

.PARAMETER FailOnWarnings
    Treat warnings as failures, causing the script to exit with an error code.

.PARAMETER SkipRemainingOnFailure
    Stop execution immediately after the first test failure, rather than
    continuing to run remaining tests.

.PARAMETER DryRun
    Show what tests would be run without actually executing them. Useful for
    validating test selection and configuration.

.PARAMETER CI
    Enable CI mode with optimized settings for continuous integration environments.
    Sets output format to Normal, enables coverage if not specified, and treats
    warnings as failures.

.PARAMETER Verbose
    Enable verbose output with additional diagnostic information.

.PARAMETER Quiet
    Enable quiet mode with minimal output. Overrides OutputFormat to Minimal.

.PARAMETER TestResultPath
    Directory path where test result files should be saved. If not specified,
    defaults to 'scripts/data/test-results'. Creates directory if it doesn't exist.

.PARAMETER CoverageReportPath
    Directory path where coverage report files should be saved. If not specified,
    defaults to 'scripts/data/coverage'. Creates directory if it doesn't exist.

.PARAMETER MaxRetries
    Maximum number of retry attempts for failed tests (0-10). Useful for handling
    flaky tests. Requires -RetryOnFailure to be effective. Defaults to 0 (no retries).

.PARAMETER RetryDelaySeconds
    Base delay in seconds between retry attempts (0-60). Used with -MaxRetries.
    Defaults to 1 second.

.PARAMETER ExponentialBackoff
    Enable exponential backoff for retry delays. When enabled, retry delays increase
    exponentially (1s, 2s, 4s, etc.). Used with -MaxRetries.

.PARAMETER RetryOnFailure
    Only retry tests that actually fail, not tests that encounter setup errors.
    Used with -MaxRetries. Defaults to true when retries are enabled.

.PARAMETER TrackPerformance
    Enable performance monitoring during test execution. Tracks execution time
    and optionally memory/CPU usage.

.PARAMETER TrackMemory
    Enable memory usage tracking during test execution. Requires -TrackPerformance.
    Monitors peak and average memory consumption.

.PARAMETER TrackCPU
    Enable CPU usage tracking during test execution. Requires -TrackPerformance.
    Monitors CPU utilization patterns.

.PARAMETER HealthCheck
    Perform environment health checks before running tests. Validates that required
    modules, paths, and tools are available. Fails in strict mode if checks fail.

.PARAMETER AnalyzeResults
    Generate detailed analysis of test results including failure patterns,
    performance insights, and actionable recommendations.

.PARAMETER ReportFormat
    Generate a custom test report in the specified format. Valid values are JSON, HTML, or Markdown.
    Requires -AnalyzeResults for full analysis data.

.PARAMETER ReportPath
    Path to save the custom test report. If not specified, report is generated but not saved.

.PARAMETER IncludeReportDetails
    Include detailed test information (passed/failed test lists) in custom reports.
    Used with -ReportFormat.

.PARAMETER Progress
    Display progress indicators during test execution for long-running test suites.

.PARAMETER MaxParallelThreads
    Override the maximum number of parallel threads for test execution (1-100).
    Takes precedence over -Parallel parameter.

.PARAMETER StrictMode
    Enable strict mode for enhanced error checking and validation.
    Causes script to fail on health check failures and other non-critical issues.

.PARAMETER ExcludeCategories
    Exclude tests from the specified categories. Categories are determined from
    test file names, tags, and test names. Common categories: Unit, Integration, Performance.

.PARAMETER OnlyCategories
    Run only tests from the specified categories. Takes precedence over -ExcludeCategories.
    Categories are determined from test file names, tags, and test names.

.PARAMETER FailFast
    Stop execution immediately after the first test failure, rather than
    continuing to run remaining tests. Similar to -SkipRemainingOnFailure.

.PARAMETER TestTimeoutSeconds
    Maximum time in seconds to allow individual tests to run (1-3600).
    Tests exceeding this timeout are aborted. Takes precedence over -Timeout.

.PARAMETER GenerateBaseline
    Generate a performance baseline file for future comparisons.
    Saves baseline data to -BaselinePath or default location.

.PARAMETER BaselinePath
    Path to save or load performance baseline data. Used with -GenerateBaseline
    or -CompareBaseline.

.PARAMETER CompareBaseline
    Compare current test performance against a saved baseline.
    Requires baseline file at -BaselinePath.

.PARAMETER BaselineThreshold
    Acceptable deviation percentage from baseline (0-100). When comparing against
    baseline, deviations exceeding this threshold will cause warnings or failures.
    Defaults to 5%.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1

    Runs all Pester tests with detailed output.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Suite Integration

    Runs only integration tests.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -TestFile tests\integration\profile.tests.ps1

    Runs only the specified test file.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -TestName "*Edit-Profile*"

    Runs tests with names containing "Edit-Profile".

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -IncludeTag "Slow" -Parallel 4

    Runs only tests tagged as "Slow" in parallel with 4 threads.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Coverage -MinimumCoverage 80

    Runs all tests with code coverage, requiring at least 80% coverage.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -OutputFormat Minimal -OutputPath results.xml

    Runs tests with minimal output and saves results to XML file.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Randomize -Repeat 3 -FailOnWarnings

    Runs tests 3 times in random order, treating warnings as failures.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Suite Unit -ExcludeTag "Integration" -Timeout 300

    Runs unit tests excluding integration-tagged tests with a 5-minute timeout.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -DryRun -TestName "*Profile*"

    Shows which tests would run for profile-related tests without executing them.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -CI -TestResultPath "ci/results"

    Runs tests in CI mode with results saved to custom directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Quiet -Coverage -ShowCoverageSummary

    Runs tests quietly but shows coverage summary.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -MaxRetries 3 -RetryOnFailure -TrackPerformance

    Runs tests with retry logic for failed tests and performance monitoring.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -HealthCheck -StrictMode -AnalyzeResults

    Performs environment health checks, runs in strict mode, and generates analysis.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -OnlyCategories Unit,Integration -Parallel 4

    Runs only unit and integration tests in parallel with 4 threads.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -AnalyzeResults -ReportFormat HTML -ReportPath "test-report.html"

    Runs tests with analysis and generates an HTML report.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -GenerateBaseline -BaselinePath "performance-baseline.json"

    Runs tests and generates a performance baseline for future comparisons.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-pester.ps1 -CompareBaseline -BaselineThreshold 10

    Runs tests and compares performance against saved baseline with 10% tolerance.
#>

param(
    [string]$TestFile,

    [string]$Suite = 'All',

    [string]$TestName = "",

    [string[]]$IncludeTag,

    [string[]]$ExcludeTag,

    [string]$OutputFormat = 'Detailed',

    [string]$OutputPath,

    [switch]$Coverage,

    [string]$CodeCoverageOutputFormat = 'JaCoCo',

    [int]$MinimumCoverage,

    [switch]$ShowCoverageSummary,

    [int]$Parallel,

    [switch]$Randomize,

    [ValidateRange(1, 100)]
    [int]$Repeat = 1,

    [ValidateRange(1, 2147483647)]
    [Nullable[int]]$Timeout,

    [switch]$FailOnWarnings,

    [switch]$SkipRemainingOnFailure,

    [switch]$DryRun,

    [switch]$CI,

    [switch]$Verbose,

    [switch]$Quiet,

    [string]$TestResultPath,

    [string]$CoverageReportPath,

    [int]$MaxRetries = 0,

    [int]$RetryDelaySeconds = 1,

    [switch]$ExponentialBackoff,

    [switch]$RetryOnFailure,

    [switch]$TrackPerformance,

    [switch]$TrackMemory,

    [switch]$TrackCPU,

    [switch]$HealthCheck,

    [switch]$AnalyzeResults,

    [string]$ReportFormat,

    [string]$ReportPath,

    [switch]$IncludeReportDetails,

    [switch]$Progress,

    [int]$MaxParallelThreads,

    [switch]$StrictMode,

    [string[]]$ExcludeCategories,

    [string[]]$OnlyCategories,

    [switch]$FailFast,

    [Nullable[int]]$TestTimeoutSeconds,

    [switch]$GenerateBaseline,

    [string]$BaselinePath,

    [switch]$CompareBaseline,

    [int]$BaselineThreshold = 5
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
try {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop -Global
    
    # Import shared utilities using ModuleImport (with Global to make functions available to script)
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
}
catch {
    Write-Host "Failed to import required modules: $_"
    throw
}

# Import local modules directly (no barrel files)
$modulesPath = Join-Path $PSScriptRoot 'modules'
try {
    # Import PesterConfig submodules first (PesterConfig.psm1 imports these, but we import directly to remove barrel pattern)
    Import-Module (Join-Path $modulesPath 'PesterOutputConfig.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'PesterCoverageConfig.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'PesterExecutionConfig.psm1') -DisableNameChecking -ErrorAction Stop
    # Import PesterConfig.psm1 (defines New-PesterTestConfiguration, imports submodules but they're already loaded)
    Import-Module (Join-Path $modulesPath 'PesterConfig.psm1') -DisableNameChecking -ErrorAction Stop
    
    # Import test discovery modules (TestDiscovery.psm1 barrel file - import submodules directly)
    Import-Module (Join-Path $modulesPath 'TestPathResolution.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestPathUtilities.psm1') -DisableNameChecking -ErrorAction Stop
    
    # Import output utilities (OutputUtils.psm1 barrel file - import submodules directly)
    Import-Module (Join-Path $modulesPath 'OutputPathUtils.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $modulesPath 'OutputSanitizer.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $modulesPath 'OutputInterceptor.psm1') -DisableNameChecking -ErrorAction Stop -Global
    
    # Import test execution modules (TestExecution.psm1 barrel file - import submodules directly)
    Import-Module (Join-Path $modulesPath 'TestRetry.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestEnvironment.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestPerformanceMonitoring.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestTimeoutHandling.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestRecovery.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestSummaryGeneration.psm1') -DisableNameChecking -ErrorAction Stop
    
    # Import test reporting modules (TestReporting.psm1 barrel file - import submodules directly, but keep TestReporting.psm1 for Get-TestAnalysisReport)
    Import-Module (Join-Path $modulesPath 'TestFailureAnalysis.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestPerformanceAnalysis.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestCategorization.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestRecommendations.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestTrendAnalysis.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestReportFormats.psm1') -DisableNameChecking -ErrorAction Stop
    # BaselineManagement.psm1 barrel file - import submodules directly
    Import-Module (Join-Path $modulesPath 'BaselineGeneration.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'BaselineComparison.psm1') -DisableNameChecking -ErrorAction Stop
    # Import TestReporting.psm1 (defines Get-TestAnalysisReport, imports submodules but they're already loaded)
    Import-Module (Join-Path $modulesPath 'TestReporting.psm1') -DisableNameChecking -ErrorAction Stop
    
    # Import test runner helpers (for Invoke-TestDryRun)
    Import-Module (Join-Path $modulesPath 'TestRunnerHelpers.psm1') -DisableNameChecking -ErrorAction Stop
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $testsDir = Join-Path $repoRoot 'tests'
    $profileDir = Join-Path $repoRoot 'profile.d'
    $testSupportPath = Join-Path $testsDir 'TestSupport.ps1'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

if (-not (Test-Path -LiteralPath $testSupportPath)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Test support script not found at $testSupportPath"
}

. $testSupportPath

# Initialize output utilities
Initialize-OutputUtils -RepoRoot $repoRoot

# Ensure Pester 5+ is available and imported
$requiredPesterVersion = [version]'5.0.0'

try {
    Ensure-ModuleAvailable -ModuleName 'Pester'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$installedPester = Get-Module -ListAvailable -Name 'Pester' | Sort-Object Version -Descending | Select-Object -First 1
if (-not $installedPester -or $installedPester.Version -lt $requiredPesterVersion) {
    try {
        Write-ScriptMessage -Message "Installing Pester $requiredPesterVersion or newer"
        Install-RequiredModule -ModuleName 'Pester' -Scope 'CurrentUser' -Force
        $installedPester = Get-Module -ListAvailable -Name 'Pester' | Sort-Object Version -Descending | Select-Object -First 1
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

if (-not $installedPester -or $installedPester.Version -lt $requiredPesterVersion) {
    $message = "Pester $requiredPesterVersion or newer is required but could not be installed."
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $message
}

try {
    Import-Module -Name 'Pester' -MinimumVersion $requiredPesterVersion -Force -ErrorAction Stop
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Using Pester v$($installedPester.Version)"

# Perform health check if requested
if ($HealthCheck) {
    Write-ScriptMessage -Message "Performing environment health check..."
    $healthResults = Test-TestEnvironmentHealth -CheckModules -CheckPaths -CheckTools

    if (-not $healthResults.Passed) {
        Write-ScriptMessage -Message "Health check failed:" -LogLevel 'Error'
        foreach ($check in $healthResults.Checks | Where-Object { -not $_.Passed }) {
            Write-ScriptMessage -Message "  - $($check.Name): $($check.Message)" -LogLevel 'Error'
        }

        if ($StrictMode) {
            Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Environment health check failed"
        }
        else {
            Write-ScriptMessage -Message "Continuing despite health check failures..." -LogLevel 'Warning'
        }
    }
    else {
        Write-ScriptMessage -Message "Environment health check passed"
    }
}

# Get environment information
$environmentInfo = Get-TestEnvironment

# Set test mode for profile fragments that need it
$env:PS_PROFILE_TEST_MODE = '1'

# Set up mocks for file-opening functions to prevent applications from launching during tests
# This must happen after test mode is set but before profile fragments are loaded
if (Get-Command 'Initialize-TestMocks' -ErrorAction SilentlyContinue) {
    Initialize-TestMocks
}

# Prevent recursive execution - if we're already running tests, don't run again
if ($env:PS_PROFILE_TEST_RUNNER_ACTIVE -eq '1') {
    Write-ScriptMessage -Message "Test runner is already active. Skipping recursive execution to prevent infinite loops." -LogLevel 'Warning'
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Recursive test execution detected and prevented"
}

# Mark that we're running tests
$env:PS_PROFILE_TEST_RUNNER_ACTIVE = '1'

# Create Pester configuration using modular function
$configParams = @{
    OutputFormat             = $OutputFormat
    CI                       = $CI
    OutputPath               = $OutputPath
    TestResultPath           = $TestResultPath
    Coverage                 = $Coverage
    ShowCoverageSummary      = $ShowCoverageSummary
    CodeCoverageOutputFormat = $CodeCoverageOutputFormat
    CoverageReportPath       = $CoverageReportPath
    MinimumCoverage          = $MinimumCoverage
    Randomize                = $Randomize
    FailOnWarnings           = $FailOnWarnings
    SkipRemainingOnFailure   = $SkipRemainingOnFailure
    Quiet                    = $Quiet
    Verbose                  = $Verbose
    ProfileDir               = $profileDir
    RepoRoot                 = $repoRoot
}

if ($Parallel -gt 0) {
    $configParams.Parallel = $Parallel
}

if ($null -ne $Timeout) {
    $configParams['Timeout'] = $Timeout
}

# Handle new advanced parameters
if ($MaxParallelThreads -and $MaxParallelThreads -gt 0) {
    $configParams.Parallel = $MaxParallelThreads
}

if ($TestTimeoutSeconds -and $TestTimeoutSeconds -gt 0) {
    $configParams['Timeout'] = $TestTimeoutSeconds
}

if ($FailFast) {
    $configParams.SkipRemainingOnFailure = $true
}

$config = New-PesterTestConfiguration @configParams

# Validate configuration before proceeding
try {
    # Test that the configuration is valid by checking key properties
    if (-not $config.Run.Path -or $config.Run.Path.Count -eq 0) {
        throw "No test paths configured"
    }

    # Validate that at least some test paths exist
    $existingPaths = $config.Run.Path.Value | Where-Object { Test-Path $_ }
    if ($existingPaths.Count -eq 0) {
        Write-ScriptMessage -Message "Warning: None of the configured test paths exist: $($config.Run.Path.Value -join ', ')" -LogLevel 'Warning'
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -ErrorRecord $_
}

# Configure test filters using modular function
$filterParams = @{
    TestName   = $TestName
    IncludeTag = $IncludeTag
    ExcludeTag = $ExcludeTag
}

# Handle category filtering
if ($OnlyCategories) {
    $filterParams.IncludeTag = $OnlyCategories
}

if ($ExcludeCategories) {
    $filterParams.ExcludeTag = $ExcludeCategories
}

$config = Set-PesterTestFilters -Config $config @filterParams

# Get test paths using modular function
$testPaths = Get-TestPaths -Suite $Suite -TestFile $TestFile -RepoRoot $repoRoot

# Filter test paths to exclude test-runner test files
$filteredTestPaths = Filter-TestPaths -TestPaths $testPaths -TestRunnerScriptPath $PSCommandPath

if ($filteredTestPaths.Count -eq 0) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "No valid test paths found after filtering"
}

if ($Verbose) {
    Write-ScriptMessage -Message "Discovered $($filteredTestPaths.Count) test path(s): $($filteredTestPaths -join ', ')" -LogLevel 'Info'
}

# Set test paths in configuration
$config.Run.Path = $filteredTestPaths


# Start output interception using modular function
Start-TestOutputInterceptor

try {
    if ($DryRun) {
        Invoke-TestDryRun -Config $config -TestPaths $filteredTestPaths
        Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Dry run completed"
    }

    # Prepare test execution script block
    # Capture variables in closure to avoid scoping issues
    $timeoutValue = if ($null -ne $Timeout -and $Timeout -gt 0) { $Timeout } else { $null }
    $script:capturedTestPaths = $filteredTestPaths
    $testExecutionScript = {
        param($config, $runNumber, $totalRuns)
        Invoke-PesterWithTimeout -Config $config -TestPaths $script:capturedTestPaths -Timeout $timeoutValue -RunNumber $runNumber -TotalRuns $totalRuns
    }

    # Execute tests with performance tracking if requested
    $executionScript = $testExecutionScript
    if ($TrackPerformance) {
        $executionScript = {
            param($config, $runNumber, $totalRuns)
            Invoke-TestExecutionWithPerformance -ExecutionScriptBlock $testExecutionScript -Config $config -RunNumber $runNumber -TotalRuns $totalRuns -TrackMemory:$TrackMemory -TrackCPU:$TrackCPU
        }
    }

    # Execute tests with retry logic if requested
    $finalResult = $null
    $performanceData = $null

    # Safety check: prevent accidental infinite loops
    if ($Repeat -gt 10 -and -not $CI) {
        Write-ScriptMessage -Message "Warning: Repeat value ($Repeat) is high. Use -CI flag or reduce Repeat value to prevent long execution times." -LogLevel 'Warning'
    }

    if ($MaxRetries -gt 0) {
        $retryScript = {
            param($config, $runNumber, $totalRuns)
            Invoke-TestWithRetry -ScriptBlock {
                & $executionScript $config $runNumber $totalRuns
            } -MaxRetries $MaxRetries -RetryDelaySeconds $RetryDelaySeconds -ExponentialBackoff:$ExponentialBackoff -RetryOnFailure:$RetryOnFailure
        }

        for ($run = 1; $run -le $Repeat; $run++) {
            if ($Verbose) {
                Write-ScriptMessage -Message "Test run $run of $Repeat" -LogLevel 'Info'
            }
            $result = & $retryScript $config $run $Repeat

            # Handle performance tracking results
            if ($TrackPerformance -and $result.Result) {
                $performanceData = $result.Performance
                $result = $result.Result
            }

            $finalResult = $result

            # If any run fails and we're not repeating, break
            if ($result.FailedCount -gt 0 -and $Repeat -eq 1) {
                break
            }
        }
    }
    else {
        for ($run = 1; $run -le $Repeat; $run++) {
            if ($Repeat -gt 1) {
                Write-ScriptMessage -Message "Test run $run of $Repeat" -LogLevel 'Info'
            }
            $result = & $executionScript $config $run $Repeat

            # Handle performance tracking results
            if ($TrackPerformance -and $result.Result) {
                $performanceData = $result.Performance
                $result = $result.Result
            }

            $finalResult = $result

            # If any run fails and we're not repeating, break
            if ($result.FailedCount -gt 0 -and $Repeat -eq 1) {
                break
            }
        }
    }

    $result = $finalResult

    # Generate analysis report if requested
    $analysis = $null
    if ($AnalyzeResults) {
        Write-ScriptMessage -Message "Generating test analysis report..."
        try {
            $analysis = Get-TestAnalysisReport -TestResult $result -IncludePerformance:$TrackPerformance

            # Display key insights
            if ($analysis.Recommendations -and $analysis.Recommendations.Count -gt 0) {
                Write-ScriptMessage -Message "Analysis Recommendations:" -LogLevel 'Info'
                foreach ($rec in $analysis.Recommendations) {
                    Write-ScriptMessage -Message "  - $rec" -LogLevel 'Info'
                }
            }
        }
        catch {
            Write-ScriptMessage -Message "Failed to generate analysis report: $($_.Exception.Message)" -LogLevel 'Warning'
            Write-ScriptMessage -Message "Continuing without analysis..." -LogLevel 'Info'
        }
    }

    # Generate custom report if requested
    if ($ReportFormat) {
        Write-ScriptMessage -Message "Generating $ReportFormat test report..."
        try {
            $reportContent = New-CustomTestReport -TestResult $result -Analysis $analysis -Format $ReportFormat -OutputPath $ReportPath -IncludeDetails:$IncludeReportDetails
            if (-not $ReportPath) {
                Write-ScriptMessage -Message "Report generated (not saved to file)"
            }
        }
        catch {
            Write-ScriptMessage -Message "Failed to generate custom report: $($_.Exception.Message)" -LogLevel 'Warning'
            Write-ScriptMessage -Message "Continuing without custom report..." -LogLevel 'Info'
        }
    }

    # Generate performance baseline if requested
    if ($GenerateBaseline) {
        Write-ScriptMessage -Message "Generating performance baseline..."
        try {
            $baselinePath = $BaselinePath
            if (-not $baselinePath) {
                $baselinePath = Join-Path $repoRoot 'performance-baseline.json'
            }

            $baseline = New-PerformanceBaseline -TestResult $result -PerformanceData $performanceData -OutputPath $baselinePath
        }
        catch {
            Write-ScriptMessage -Message "Failed to generate performance baseline: $($_.Exception.Message)" -LogLevel 'Warning'
            Write-ScriptMessage -Message "Continuing without baseline generation..." -LogLevel 'Info'
        }
    }

    # Compare against baseline if requested
    if ($CompareBaseline) {
        Write-ScriptMessage -Message "Comparing performance against baseline..."
        try {
            $baselinePath = $BaselinePath
            if (-not $baselinePath) {
                $baselinePath = Join-Path $repoRoot 'performance-baseline.json'
            }

            $comparison = Compare-PerformanceBaseline -TestResult $result -PerformanceData $performanceData -BaselinePath $baselinePath -Threshold $BaselineThreshold

            if ($comparison.Success) {
                # Display comparison results
                if ($comparison.OverallChange.DurationChange) {
                    $change = $comparison.OverallChange.DurationChange
                    $status = if ($change.IsRegression) { "REGRESSION" } elseif ($change.IsImprovement) { "IMPROVEMENT" } else { "STABLE" }
                    Write-ScriptMessage -Message "Overall Duration: $($change.Baseline) -> $($change.Current) ($($change.ChangePercent)%) - $status" -LogLevel $(if ($change.IsRegression) { 'Warning' } else { 'Info' })
                }

                if ($comparison.Regressions.Count -gt 0) {
                    Write-ScriptMessage -Message "Performance Regressions Detected:" -LogLevel 'Warning'
                    foreach ($regression in $comparison.Regressions) {
                        Write-ScriptMessage -Message "  $($regression.TestName): $($regression.ChangePercent)% slower" -LogLevel 'Warning'
                    }
                }

                if ($comparison.Improvements.Count -gt 0) {
                    Write-ScriptMessage -Message "Performance Improvements Detected:" -LogLevel 'Info'
                    foreach ($improvement in $comparison.Improvements) {
                        Write-ScriptMessage -Message "  $($improvement.TestName): $($improvement.ChangePercent)% faster" -LogLevel 'Info'
                    }
                }

                # Generate regression report if there are significant changes
                if ($comparison.Regressions.Count -gt 0 -or $comparison.Improvements.Count -gt 0) {
                    try {
                        $reportPath = Join-Path $repoRoot 'performance-regression-report.txt'
                        New-PerformanceRegressionReport -Comparison $comparison -OutputPath $reportPath
                    }
                    catch {
                        Write-ScriptMessage -Message "Failed to generate regression report: $($_.Exception.Message)" -LogLevel 'Warning'
                    }
                }
            }
            else {
                Write-ScriptMessage -Message "Baseline comparison failed: $($comparison.Message)" -LogLevel 'Warning'
            }
        }
        catch {
            Write-ScriptMessage -Message "Failed to compare against baseline: $($_.Exception.Message)" -LogLevel 'Warning'
            Write-ScriptMessage -Message "Continuing without baseline comparison..." -LogLevel 'Info'
        }
    }

}
finally {
    # Stop output interception using modular function (if available)
    if (Get-Command -Name 'Stop-TestOutputInterceptor' -ErrorAction SilentlyContinue) {
        Stop-TestOutputInterceptor
    }
    
    # Clear the active flag
    $env:PS_PROFILE_TEST_RUNNER_ACTIVE = $null
    
    Pop-Location
}

$result
