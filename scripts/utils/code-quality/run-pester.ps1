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
    Optional path to one or more specific test files or directories to run. If not specified,
    runs all tests in the tests directory. Supports wildcards and relative paths.
    Can accept multiple files as an array. Use -Path as an alias.

.PARAMETER Path
    Alias for -TestFile. Optional path to one or more specific test files or directories to run.
    Supports wildcards and relative paths. Can accept multiple files as an array.

.PARAMETER Suite
    The test suite to run. Valid values are All, Unit, Integration, or Performance.
    Defaults to All. When TestFile or Path is specified, this parameter is ignored.

.PARAMETER TestName
    Optional filter for test names. Supports wildcards and multiple patterns
    separated by " or ", commas, or semicolons. Examples: "*Edit-Profile*", 
    "*Backup* or *Restore*", "*profile-shortcuts*, *profile-system-utilities*",
    "*profile-shortcuts* or *profile-system-utilities* or *utility-path-validation*".

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
    of parallel threads (1-100). If -Parallel is specified without a value,
    defaults to the number of logical processors (capped at 16). If not specified,
    tests run sequentially. Note: Code coverage collection may reduce parallel
    execution benefits.

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

.PARAMETER ListTests
    List all available tests without running them. Shows test files, test counts, and test names.
    Use -ShowDetails to display full test structure including Describe and Context blocks.

.PARAMETER ShowDetails
    When used with -ListTests, shows detailed test structure including Describe and Context blocks.

.PARAMETER FailedOnly
    Re-run only tests that failed in the last test run. Reads the most recent test result file
    and filters to only failed tests. Requires a previous test run with saved results.

.PARAMETER ChangedFiles
    Run tests for files that have been changed in the git working directory.
    Automatically maps changed source files to their corresponding test files.

.PARAMETER ChangedSince
    Run tests for files changed since a specific git commit, branch, or tag.
    Example: -ChangedSince "main" or -ChangedSince "HEAD~5". Defaults to "HEAD~1" if not specified.

.PARAMETER IncludeUntracked
    When used with -ChangedFiles, includes untracked files in the changed files list.

.PARAMETER ConfigFile
    Load test runner configuration from a JSON file. Configuration file can contain
    any test runner parameters. Command-line parameters override config file values.

.PARAMETER SaveConfig
    Save current test runner configuration to a JSON file for later use with -ConfigFile.

.PARAMETER Watch
    Enable watch mode. Automatically re-runs tests when files change. Monitors test files
    and source files for changes. Press Ctrl+C to stop watching.

.PARAMETER WatchDebounceSeconds
    Number of seconds to wait after a file change before triggering tests in watch mode.
    Defaults to 1 second. Prevents excessive test runs when multiple files change quickly.

.PARAMETER TestFilePattern
    Filter test files by name pattern. Only test files matching the pattern will be run.
    Supports wildcards. Example: -TestFilePattern "*integration*" or "*unit*".

.PARAMETER ShowSummaryStats
    Show enhanced summary statistics including slowest tests, failure patterns, and
    performance metrics after test execution.

.PARAMETER Interactive
    Enable interactive mode to select which tests to run from a menu. Presents available
    tests and allows selection by file number, pattern filtering, or selecting all tests.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1

    Runs all Pester tests with detailed output.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration

    Runs only integration tests.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile tests/integration/profile.tests.ps1

    Runs only the specified test file.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/integration/profile.tests.ps1

    Runs only the specified test file using the -Path alias.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile tests/unit/*.tests.ps1, tests/integration/profile.tests.ps1

    Runs multiple test files specified as an array.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestName "*Edit-Profile*"

    Runs tests with names containing "Edit-Profile".

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit -TestName "*profile-shortcuts* or *profile-system-utilities* or *utility-path-validation* or *utility-scripts*"

    Runs unit tests matching any of the specified patterns using "or" syntax.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestName "*profile-shortcuts*, *profile-system-utilities*, *utility-path-validation*"

    Runs tests matching any of the specified patterns using comma-separated syntax.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -IncludeTag "Slow" -Parallel 4

    Runs only tests tagged as "Slow" in parallel with 4 threads.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -MinimumCoverage 80

    Runs all tests with code coverage, requiring at least 80% coverage.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -OutputFormat Minimal -OutputPath results.xml

    Runs tests with minimal output and saves results to XML file.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Randomize -Repeat 3 -FailOnWarnings

    Runs tests 3 times in random order, treating warnings as failures.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit -ExcludeTag "Integration" -Timeout 300

    Runs unit tests excluding integration-tagged tests with a 5-minute timeout.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -DryRun -TestName "*Profile*"

    Shows which tests would run for profile-related tests without executing them.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CI -TestResultPath "ci/results"

    Runs tests in CI mode with results saved to custom directory.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Quiet -Coverage -ShowCoverageSummary

    Runs tests quietly but shows coverage summary.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -RetryOnFailure -TrackPerformance

    Runs tests with retry logic for failed tests and performance monitoring.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -HealthCheck -StrictMode -AnalyzeResults

    Performs environment health checks, runs in strict mode, and generates analysis.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -OnlyCategories Unit,Integration -Parallel 4

    Runs only unit and integration tests in parallel with 4 threads.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -AnalyzeResults -ReportFormat HTML -ReportPath "test-report.html"

    Runs tests with analysis and generates an HTML report.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -GenerateBaseline -BaselinePath "performance-baseline.json"

    Runs tests and generates a performance baseline for future comparisons.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CompareBaseline -BaselineThreshold 10

    Runs tests and compares performance against saved baseline with 10% tolerance.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ListTests

    Lists all available tests without running them.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ListTests -ShowDetails

    Lists all available tests with detailed structure including Describe and Context blocks.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -FailedOnly

    Re-runs only tests that failed in the last test run.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ChangedFiles

    Runs tests for files changed in the git working directory.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ChangedSince main

    Runs tests for files changed since the main branch.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -SaveConfig test-config.json

    Saves current configuration to test-config.json for later use.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ConfigFile test-config.json

    Loads configuration from test-config.json and runs tests with those settings.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Watch

    Watches for file changes and automatically re-runs tests when changes are detected.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFilePattern "*integration*"

    Runs only test files with "integration" in their name.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ShowSummaryStats

    Shows enhanced summary statistics including slowest tests and failure patterns.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Interactive

    Presents an interactive menu to select which tests to run.
#>

param(
    [Alias('Path')]
    [string[]]$TestFile,

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

    [Nullable[int]]$Parallel,

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

    [switch]$SuppressRetryWarnings,

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

    [int]$BaselineThreshold = 5,

    [switch]$ListTests,

    [switch]$ShowDetails,

    [switch]$FailedOnly,

    [switch]$ChangedFiles,

    [string]$ChangedSince,

    [switch]$IncludeUntracked,

    [string]$ConfigFile,

    [string]$SaveConfig,

    [switch]$Watch,

    [int]$WatchDebounceSeconds = 1,

    [string]$TestFilePattern,

    [switch]$ShowSummaryStats,

    [switch]$Interactive
)

# Suppress all confirmation prompts for non-interactive execution (similar to analyze-coverage.ps1)
# This script should never require user input - always run non-interactively
# Must be set immediately after param block, before any operations that might prompt
$ErrorActionPreference = 'Stop'
$ConfirmPreference = 'None'
$global:ConfirmPreference = 'None'

# Set default parameter values to suppress prompts for Remove-Item and other operations
# This must be set before any test execution to prevent confirmation prompts
if (-not $PSDefaultParameterValues) {
    $PSDefaultParameterValues = @{}
}
$PSDefaultParameterValues['Remove-Item:Confirm'] = $false
$PSDefaultParameterValues['Remove-Item:Force'] = $true
$PSDefaultParameterValues['Remove-Item:Recurse'] = $true
$PSDefaultParameterValues['Clear-Item:Confirm'] = $false
$PSDefaultParameterValues['Clear-Item:Force'] = $true

# Ensure these are set globally so they apply to all scopes (including test execution)
$global:PSDefaultParameterValues = if ($global:PSDefaultParameterValues) {
    $global:PSDefaultParameterValues
}
else {
    @{}
}
$global:PSDefaultParameterValues['Remove-Item:Confirm'] = $false
$global:PSDefaultParameterValues['Remove-Item:Force'] = $true
$global:PSDefaultParameterValues['Remove-Item:Recurse'] = $true
$global:PSDefaultParameterValues['Clear-Item:Confirm'] = $false
$global:PSDefaultParameterValues['Clear-Item:Force'] = $true

# Set environment variables to suppress confirmations in profile fragments
$env:PS_PROFILE_SUPPRESS_CONFIRMATIONS = '1'
$env:PS_PROFILE_FORCE = '1'

# Write initial output immediately to ensure user sees progress
Write-Host "Starting Pester test runner..." -ForegroundColor Cyan

# Resolve script root for relative paths (similar to analyze-coverage.ps1)
# Script is in scripts/utils/code-quality/, need to go up 3 levels to repo root
$scriptRoot = $PSScriptRoot
for ($i = 1; $i -le 3; $i++) {
    $scriptRoot = Split-Path -Parent $scriptRoot
}
if (-not (Test-Path $scriptRoot)) {
    $scriptRoot = $PWD
}

# Import shared utilities directly (similar to analyze-coverage.ps1)
# Calculate lib path manually to avoid circular dependency with Get-RepoRoot
$libPath = Join-Path $scriptRoot 'scripts' 'lib'
try {
    Write-Host "Loading shared modules..." -ForegroundColor Yellow
    
    # Import core modules first (needed by others)
    $corePath = Join-Path $libPath 'core'
    Import-Module (Join-Path $corePath 'ExitCodes.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'path' 'PathResolution.psm1') -DisableNameChecking -ErrorAction Stop -Global
    
    # Now we can use Get-RepoRoot if needed, but continue with direct imports for consistency
    Import-Module (Join-Path $corePath 'Logging.psm1') -DisableNameChecking -ErrorAction Stop -Global
    
    # Locale and Module may not exist - import only if available
    $localePath = Join-Path $libPath 'utilities' 'Locale.psm1'
    if (Test-Path $localePath) {
        Import-Module $localePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
    }
    
    $modulePath = Join-Path $libPath 'runtime' 'Module.psm1'
    if (Test-Path $modulePath) {
        Import-Module $modulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
    }
    
    Write-Host "Shared modules loaded" -ForegroundColor Green
}
catch {
    Write-Host "Failed to import required modules: $_" -ForegroundColor Red
    throw
}

# Import local modules directly (no barrel files)
Write-Host "Loading test runner modules..." -ForegroundColor Yellow
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
    
    # Import new feature modules
    Import-Module (Join-Path $modulesPath 'TestGitIntegration.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestResultReader.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestLister.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestConfigFile.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestWatcher.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestSummaryStats.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $modulesPath 'TestInteractive.psm1') -DisableNameChecking -ErrorAction Stop
    
    Write-Host "Test runner modules loaded" -ForegroundColor Green
}
catch {
    Write-Host "Failed to import test runner modules: $_" -ForegroundColor Red
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Helper function to exit while ensuring cleanup
# Must be defined after modules are imported but before any calls to it
function Exit-WithCleanup {
    param(
        [int]$ExitCode,
        [string]$Message,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    # Clear the active flag before exiting
    $env:PS_PROFILE_TEST_RUNNER_ACTIVE = $null
    # Use Get-Command to ensure we can find Exit-WithCode (it's imported globally)
    $exitCmd = Get-Command -Name 'Exit-WithCode' -ErrorAction SilentlyContinue
    if ($exitCmd) {
        & $exitCmd -ExitCode $ExitCode -Message $Message -ErrorRecord $ErrorRecord
    }
    else {
        # Fallback: if Exit-WithCode isn't available, just exit directly
        if ($ErrorRecord) {
            Write-Error -ErrorRecord $ErrorRecord
        }
        elseif ($Message) {
            Write-Host $Message -ForegroundColor Red
        }
        exit $ExitCode
    }
}

# Get repository root (use scriptRoot we already calculated, similar to analyze-coverage.ps1)
Write-Host "Resolving repository paths..." -ForegroundColor Yellow
try {
    # Use scriptRoot we calculated above, or fall back to Get-RepoRoot if available
    if ($scriptRoot -and (Test-Path $scriptRoot)) {
        $repoRoot = $scriptRoot
    }
    elseif (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
        $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    }
    else {
        throw "Could not resolve repository root. scriptRoot: $scriptRoot"
    }
    
    $testsDir = Join-Path $repoRoot 'tests'
    $profileDir = Join-Path $repoRoot 'profile.d'
    $testSupportPath = Join-Path $testsDir 'TestSupport.ps1'
    Write-Host "Repository root: $repoRoot" -ForegroundColor Green
}
catch {
    Write-Host "Failed to resolve repository root: $_" -ForegroundColor Red
    Exit-WithCleanup -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Load configuration file if specified (before processing other parameters)
if ($ConfigFile) {
    try {
        Write-Host "Loading configuration from: $ConfigFile" -ForegroundColor Yellow
        $configParams = Load-TestConfig -ConfigPath $ConfigFile
        
        # Apply config file parameters, but command-line parameters take precedence
        foreach ($key in $configParams.Keys) {
            if (-not $PSBoundParameters.ContainsKey($key)) {
                # Set variable if not already set via command line
                Set-Variable -Name $key -Value $configParams[$key] -Scope Script
            }
        }
        Write-Host "Configuration loaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to load configuration file: $_" -ForegroundColor Red
        Exit-WithCleanup -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

if (-not (Test-Path -LiteralPath $testSupportPath)) {
    Exit-WithCleanup -ExitCode $EXIT_SETUP_ERROR -Message "Test support script not found at $testSupportPath"
}

# Ensure confirmation suppression is active before loading TestSupport (tests may run during load)
$ConfirmPreference = 'None'
$global:ConfirmPreference = 'None'
if (-not $global:PSDefaultParameterValues) {
    $global:PSDefaultParameterValues = @{}
}
$global:PSDefaultParameterValues['Remove-Item:Confirm'] = $false
$global:PSDefaultParameterValues['Remove-Item:Force'] = $true
$global:PSDefaultParameterValues['Remove-Item:Recurse'] = $true

# Load TestSupport.ps1 - it uses $PSScriptRoot to find the TestSupport subdirectory,
# so we need to set $PSScriptRoot to the tests directory temporarily
Write-Host "Loading TestSupport.ps1..." -ForegroundColor Yellow
$originalPSScriptRoot = $PSScriptRoot
$PSScriptRoot = $testsDir
. $testSupportPath
$PSScriptRoot = $originalPSScriptRoot
Write-Host "TestSupport.ps1 loaded" -ForegroundColor Green

# Re-apply confirmation suppression after TestSupport load (in case it was reset)
$ConfirmPreference = 'None'
$global:ConfirmPreference = 'None'

# Initialize output utilities
Initialize-OutputUtils -RepoRoot $repoRoot

# Ensure Pester 5+ is available and imported
Write-Host "Checking Pester availability..." -ForegroundColor Yellow
$requiredPesterVersion = [version]'5.0.0'

try {
    Ensure-ModuleAvailable -ModuleName 'Pester'
}
catch {
    Write-Host "Failed to ensure Pester is available: $_" -ForegroundColor Red
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
        Exit-WithCleanup -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

if (-not $installedPester -or $installedPester.Version -lt $requiredPesterVersion) {
    $message = "Pester $requiredPesterVersion or newer is required but could not be installed."
    Exit-WithCleanup -ExitCode $EXIT_SETUP_ERROR -Message $message
}

try {
    Import-Module -Name 'Pester' -MinimumVersion $requiredPesterVersion -Force -ErrorAction Stop
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-Host "Using Pester v$($installedPester.Version)" -ForegroundColor Cyan

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
            Exit-WithCleanup -ExitCode $EXIT_VALIDATION_FAILURE -Message "Environment health check failed"
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

# Ensure confirmation suppression is still active (in case it was reset)
$ConfirmPreference = 'None'
$global:ConfirmPreference = 'None'
$env:PS_PROFILE_SUPPRESS_CONFIRMATIONS = '1'
$env:PS_PROFILE_FORCE = '1'

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

# Wrap main execution in try-finally to ensure we always clear the flag
try {

    # Create Pester configuration using modular function
    # Enable coverage by default in CI mode or if explicitly requested
    # If -Coverage switch was provided, use it; otherwise enable in CI mode
    $enableCoverage = if ($PSBoundParameters.ContainsKey('Coverage')) {
        $Coverage
    }
    else {
        $CI  # Enable coverage automatically in CI mode
    }
    $configParams = @{
        OutputFormat             = $OutputFormat
        CI                       = $CI
        OutputPath               = $OutputPath
        TestResultPath           = $TestResultPath
        Coverage                 = $enableCoverage
        ShowCoverageSummary      = $ShowCoverageSummary -or $enableCoverage
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

    # Handle parallel execution
    # If -Parallel is specified without a value, use CPU count
    # If -Parallel has a value, use that value
    # If -MaxParallelThreads is specified, it takes precedence
    if ($MaxParallelThreads -and $MaxParallelThreads -gt 0) {
        $configParams.Parallel = $MaxParallelThreads
    }
    elseif ($PSBoundParameters.ContainsKey('Parallel')) {
        if ($Parallel -gt 0) {
            $configParams.Parallel = $Parallel
        }
        else {
            # -Parallel specified without value, use CPU count
            # Cap at reasonable maximum to avoid resource exhaustion
            $cpuCount = [System.Environment]::ProcessorCount
            $configParams.Parallel = [Math]::Min($cpuCount, 16)
        }
    }

    # Log parallel execution configuration if verbose
    if ($Verbose -and $configParams.Parallel) {
        Write-ScriptMessage -Message "Parallel execution enabled with $($configParams.Parallel) thread(s)" -LogLevel 'Info'
    }

    if ($null -ne $Timeout) {
        $configParams['Timeout'] = $Timeout
    }

    if ($TestTimeoutSeconds -and $TestTimeoutSeconds -gt 0) {
        $configParams['Timeout'] = $TestTimeoutSeconds
    }

    if ($FailFast) {
        $configParams.SkipRemainingOnFailure = $true
    }

    # Handle special modes before test discovery
    if ($FailedOnly) {
        Write-Host "Reading failed tests from last run..." -ForegroundColor Yellow
        $failedTestInfo = Get-FailedTestsFromLastRun -TestResultPath $TestResultPath -RepoRoot $repoRoot
    
        if (-not $failedTestInfo.Success) {
            Write-Host "ERROR: $($failedTestInfo.Message)" -ForegroundColor Red
            Exit-WithCleanup -ExitCode $EXIT_VALIDATION_FAILURE -Message $failedTestInfo.Message
        }
    
        if ($failedTestInfo.FailedTests.Count -eq 0) {
            Write-Host "No failed tests found in last run. All tests passed!" -ForegroundColor Green
            Exit-WithCleanup -ExitCode $EXIT_SUCCESS -Message "No failed tests to re-run"
        }
    
        Write-Host "Found $($failedTestInfo.FailedTests.Count) failed test(s)" -ForegroundColor Yellow
    
        # Map failed tests to test files
        if ($failedTestInfo.TestFiles.Count -gt 0) {
            $TestFile = $failedTestInfo.TestFiles
        }
        else {
            # Try to find test files from failed test names
            $TestFile = Get-TestFilesFromFailedTestNames -FailedTestNames $failedTestInfo.FailedTests -RepoRoot $repoRoot
            if ($TestFile.Count -eq 0) {
                Write-Host "Warning: Could not map failed tests to test files. Running all tests." -ForegroundColor Yellow
                $TestFile = $null
            }
        }
    
        # Set TestName filter to only run failed tests
        if ($failedTestInfo.FailedTests.Count -gt 0) {
            $TestName = $failedTestInfo.FailedTests -join ' or '
        }
    }

    # Handle git integration
    if ($ChangedFiles -or $ChangedSince) {
        Write-Host "Detecting changed files in git..." -ForegroundColor Yellow
    
        if ($ChangedSince) {
            $changedSourceFiles = Get-GitChangedFilesSince -Since $ChangedSince -RepoRoot $repoRoot
        }
        else {
            $changedSourceFiles = Get-GitChangedFiles -IncludeUntracked:$IncludeUntracked -RepoRoot $repoRoot
        }
    
        if ($changedSourceFiles.Count -eq 0) {
            Write-Host "No changed files found." -ForegroundColor Yellow
            if (-not $ListTests) {
                Exit-WithCleanup -ExitCode $EXIT_SUCCESS -Message "No changed files to test"
            }
        }
        else {
            Write-Host "Found $($changedSourceFiles.Count) changed file(s)" -ForegroundColor Green
        
            # Map changed files to test files
            $changedTestFiles = Get-TestFilesForSourceFiles -SourceFiles $changedSourceFiles -RepoRoot $repoRoot
        
            if ($changedTestFiles.Count -eq 0) {
                Write-Host "Warning: Could not map changed files to test files." -ForegroundColor Yellow
                Write-Host "Changed files: $($changedSourceFiles -join ', ')" -ForegroundColor Cyan
            }
            else {
                Write-Host "Mapped to $($changedTestFiles.Count) test file(s)" -ForegroundColor Green
                # Override TestFile with changed test files
                if ($TestFile) {
                    # Merge with existing TestFile
                    $TestFile = @($TestFile) + $changedTestFiles | Select-Object -Unique
                }
                else {
                    $TestFile = $changedTestFiles
                }
            }
        }
    }

    # Get test paths first (before creating config to avoid read-only issues)
    Write-Host "Discovering test files..." -ForegroundColor Yellow
    $testPaths = Get-TestPaths -Suite $Suite -TestFile $TestFile -RepoRoot $repoRoot

    # Filter test paths to exclude test-runner test files
    $filteredTestPaths = Filter-TestPaths -TestPaths $testPaths -TestRunnerScriptPath $PSCommandPath

    # Apply test file pattern filter if specified
    if ($TestFilePattern -and $filteredTestPaths.Count -gt 0) {
        $originalCount = $filteredTestPaths.Count
        $filteredTestPaths = $filteredTestPaths | Where-Object {
            $fileName = Split-Path $_ -Leaf
            $fileName -like $TestFilePattern
        }
    
        if ($filteredTestPaths.Count -eq 0) {
            Write-Host "ERROR: No test files match pattern: $TestFilePattern" -ForegroundColor Red
            Exit-WithCleanup -ExitCode $EXIT_NO_TESTS_FOUND -Message "No test files match pattern: $TestFilePattern"
        }
    
        Write-Host "Filtered to $($filteredTestPaths.Count) test file(s) matching pattern: $TestFilePattern" -ForegroundColor Green
    }

    if ($filteredTestPaths.Count -eq 0) {
        Write-Host "ERROR: No valid test paths found after filtering" -ForegroundColor Red
        Exit-WithCleanup -ExitCode $EXIT_NO_TESTS_FOUND -Message "No valid test paths found after filtering"
    }

    # Handle Interactive mode
    if ($Interactive) {
        Write-Host "`n=== Interactive Test Selection ===" -ForegroundColor Cyan
        $testList = Get-TestList -TestPaths $filteredTestPaths -RepoRoot $repoRoot
    
        if ($testList.Tests.Count -eq 0) {
            Write-Host "No tests found to select." -ForegroundColor Yellow
            Exit-WithCleanup -ExitCode $EXIT_NO_TESTS_FOUND -Message "No tests found for interactive selection"
        }
    
        $selection = Select-TestsInteractively -TestList $testList -RepoRoot $repoRoot
    
        if ($selection.Canceled) {
            $cancelMsg = if (Get-Command Get-LocalizedMessage -ErrorAction SilentlyContinue) {
                Get-LocalizedMessage -USMessage "Test selection canceled." -UKMessage "Test selection cancelled."
            }
            else {
                "Test selection canceled."
            }
            $exitMsg = if (Get-Command Get-LocalizedMessage -ErrorAction SilentlyContinue) {
                Get-LocalizedMessage -USMessage "Interactive test selection canceled" -UKMessage "Interactive test selection cancelled"
            }
            else {
                "Interactive test selection canceled"
            }
            Write-Host $cancelMsg -ForegroundColor Yellow
            Exit-WithCleanup -ExitCode $EXIT_WATCH_MODE_CANCELED -Message $exitMsg
        }
    
        # Update filtered paths to only selected files
        if ($selection.SelectedFiles.Count -gt 0) {
            $filteredTestPaths = $filteredTestPaths | Where-Object { $selection.SelectedFiles -contains $_ }
        
            if ($filteredTestPaths.Count -eq 0) {
                Write-Host "No test files selected." -ForegroundColor Yellow
                Exit-WithCleanup -ExitCode $EXIT_NO_TESTS_FOUND -Message "No test files selected"
            }
        
            Write-Host "Running $($selection.SelectedTests.Count) selected test(s) from $($filteredTestPaths.Count) file(s)" -ForegroundColor Green
        }
    }

    # Handle ListTests mode
    if ($ListTests) {
        Write-Host "`n=== Listing Tests (Not Running) ===" -ForegroundColor Cyan
        $testList = Get-TestList -TestPaths $filteredTestPaths -RepoRoot $repoRoot
        Show-TestList -TestList $testList -ShowDetails:$ShowDetails
        Exit-WithCleanup -ExitCode $EXIT_SUCCESS -Message "Test listing completed"
    }

    # Enhanced test count summary
    Write-Host "Found $($filteredTestPaths.Count) test file(s) to run" -ForegroundColor Green
    if ($Verbose) {
        Write-Host "Test files: $($filteredTestPaths -join ', ')" -ForegroundColor Cyan
    
        # Try to get test count estimate
        try {
            $testList = Get-TestList -TestPaths $filteredTestPaths -RepoRoot $repoRoot
            Write-Host "Estimated test count: $($testList.TestCount) test(s)" -ForegroundColor Cyan
        }
        catch {
            # Ignore errors in test counting - it's just a nice-to-have
        }
    }
    else {
        # Even in non-verbose mode, try to show test count
        try {
            $testList = Get-TestList -TestPaths $filteredTestPaths -RepoRoot $repoRoot
            if ($testList.TestCount -gt 0) {
                Write-Host "Estimated test count: $($testList.TestCount) test(s)" -ForegroundColor Cyan
            }
        }
        catch {
            # Ignore errors
        }
    }

    # TestSupport.ps1 is already loaded earlier (line 480) with correct $PSScriptRoot
    # All test files will have access to TestSupport functions in the global scope

    # Create configuration (pass filtered test paths for targeted coverage)
    $configParams['TestPaths'] = $filteredTestPaths
    $config = New-PesterTestConfiguration @configParams

    # Note: Path is passed directly to Invoke-Pester via -Path parameter or to Invoke-PesterWithTimeout via -TestPaths
    # We cannot set $config.Run.Path.Value as it is read-only in Pester 5

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

    # Validate configuration after setting paths
    try {
        # Validate that at least some test paths exist
        $existingPaths = $filteredTestPaths | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }
        if ($existingPaths.Count -eq 0) {
            Write-ScriptMessage -Message "Warning: None of the configured test paths exist: $($filteredTestPaths -join ', ')" -LogLevel 'Warning'
        }
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -ErrorRecord $_
    }


    # Define test execution function for watch mode (store in script scope)
    $script:executeTests = {
        param($testPaths, $testConfig, $timeoutVal)
    
        # Start output interception
        Start-TestOutputInterceptor
    
        try {
            $capturedTestPaths = $testPaths
            $execScript = {
                param($cfg, $runNum, $totalRuns)
                Invoke-PesterWithTimeout -Config $cfg -TestPaths $capturedTestPaths -Timeout $timeoutVal -RunNumber $runNum -TotalRuns $totalRuns
            }
        
            # Capture TrackPerformance, TrackMemory, TrackCPU from parent scope
            $trackPerf = $script:TrackPerformance
            $trackMem = $script:TrackMemory
            $trackCPU = $script:TrackCPU
        
            if ($trackPerf) {
                $execScript = {
                    param($cfg, $runNum, $totalRuns)
                    Invoke-TestExecutionWithPerformance -ExecutionScriptBlock $execScript -Config $cfg -RunNumber $runNum -TotalRuns $totalRuns -TrackMemory:$trackMem -TrackCPU:$trackCPU
                }
            }
        
            Write-Host "Running tests..." -ForegroundColor Yellow
            $testResult = & $execScript $testConfig 1 1
        
            if ($trackPerf -and $testResult.Result) {
                $script:watchPerformanceData = $testResult.Performance
                $testResult = $testResult.Result
            }
        
            Write-Host "Tests completed: Passed=$($testResult.PassedCount), Failed=$($testResult.FailedCount), Skipped=$($testResult.SkippedCount)" -ForegroundColor $(if ($testResult.FailedCount -eq 0) { 'Green' } else { 'Red' })
        
            return $testResult
        }
        finally {
            if (Get-Command -Name 'Stop-TestOutputInterceptor' -ErrorAction SilentlyContinue) {
                Stop-TestOutputInterceptor
            }
        }
    }

    # Handle watch mode
    if ($Watch) {
        Write-Host "`n=== Watch Mode ===" -ForegroundColor Cyan
        Write-Host "Watching for file changes. Tests will re-run automatically." -ForegroundColor Yellow
        Write-Host "Press Ctrl+C to stop watching.`n" -ForegroundColor Yellow
    
        # Determine watch paths (test files and source directories)
        $watchPaths = @()
        $watchPaths += $filteredTestPaths | ForEach-Object { Split-Path $_ -Parent } | Select-Object -Unique
        $watchPaths += $repoRoot | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }
    
        # Remove duplicates and ensure paths exist
        $watchPaths = $watchPaths | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
    
        # Capture variables for watch mode closure
        $script:watchTestPaths = $filteredTestPaths
        $script:watchConfig = $config
        $script:watchTimeout = $timeoutValue
        $script:watchShowStats = $ShowSummaryStats
        $script:watchPerformanceData = $null
    
        $onChangeScript = {
            $timeStr = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
                Format-LocaleDate (Get-Date) -Format 'HH:mm:ss'
            }
            else {
                (Get-Date -Format 'HH:mm:ss')
            }
            Write-Host "`n[$timeStr] File changed, re-running tests..." -ForegroundColor Cyan
            $testResult = & $script:executeTests $script:watchTestPaths $script:watchConfig $script:watchTimeout
        
            # Show summary stats if enabled
            if ($script:watchShowStats) {
                $summaryStats = Get-TestSummaryStatistics -TestResult $testResult -PerformanceData $script:watchPerformanceData -ShowSlowest 5
                Show-TestSummaryStatistics -Statistics $summaryStats -ShowSlowest -ShowFailurePatterns
            }
        
            Write-Host "`nWatching for changes... (Press Ctrl+C to stop)" -ForegroundColor Green
        }
    
        try {
            Start-TestWatcher -WatchPaths $watchPaths -TestFiles @('*.tests.ps1') -SourceFiles @('*.ps1', '*.psm1') -DebounceSeconds $WatchDebounceSeconds -OnChange $onChangeScript -RepoRoot $repoRoot
        }
        catch {
            $cancelMsg = if (Get-Command Get-LocalizedMessage -ErrorAction SilentlyContinue) {
                Get-LocalizedMessage -USMessage "Watch mode canceled or error occurred: $_" -UKMessage "Watch mode cancelled or error occurred: $_"
            }
            else {
                "Watch mode canceled or error occurred: $_"
            }
            $exitMsg = if (Get-Command Get-LocalizedMessage -ErrorAction SilentlyContinue) {
                Get-LocalizedMessage -USMessage "Watch mode canceled" -UKMessage "Watch mode cancelled"
            }
            else {
                "Watch mode canceled"
            }
            Write-Host $cancelMsg -ForegroundColor Yellow
            Exit-WithCleanup -ExitCode $EXIT_WATCH_MODE_CANCELED -Message $exitMsg
        }
    
        # Should not reach here, but just in case
        Exit-WithCleanup -ExitCode $EXIT_SUCCESS
    }

    # Start output interception using modular function
    Write-Host "Starting test execution..." -ForegroundColor Cyan
    Start-TestOutputInterceptor

    try {
        if ($DryRun) {
            Write-Host "DRY RUN MODE - No tests will be executed" -ForegroundColor Yellow
            Invoke-TestDryRun -Config $config -TestPaths $filteredTestPaths
            Exit-WithCleanup -ExitCode $EXIT_SUCCESS -Message "Dry run completed"
        }

        # Ensure confirmation suppression is active before test execution
        $ConfirmPreference = 'None'
        $global:ConfirmPreference = 'None'
        if (-not $global:PSDefaultParameterValues) {
            $global:PSDefaultParameterValues = @{}
        }
        $global:PSDefaultParameterValues['Remove-Item:Confirm'] = $false
        $global:PSDefaultParameterValues['Remove-Item:Force'] = $true
        $global:PSDefaultParameterValues['Remove-Item:Recurse'] = $true
        
        # Prepare test execution script block
        # Capture variables in closure to avoid scoping issues
        $timeoutValue = if ($null -ne $Timeout -and $Timeout -gt 0) { $Timeout } else { $null }
        $script:capturedTestPaths = $filteredTestPaths
        $testExecutionScript = {
            param($config, $runNumber, $totalRuns)
            # Ensure confirmation suppression in script block context
            $ConfirmPreference = 'None'
            $global:ConfirmPreference = 'None'
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
                } -MaxRetries $MaxRetries -RetryDelaySeconds $RetryDelaySeconds -ExponentialBackoff:$ExponentialBackoff -RetryOnFailure:$RetryOnFailure -SuppressRetryWarnings:$SuppressRetryWarnings
            }

            for ($run = 1; $run -le $Repeat; $run++) {
                Write-Host "`n=== Test Run $run of $Repeat ===" -ForegroundColor Cyan
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
                    Write-Host "`n=== Test Run $run of $Repeat ===" -ForegroundColor Cyan
                    Write-ScriptMessage -Message "Test run $run of $Repeat" -LogLevel 'Info'
                }
                Write-Host "Running tests..." -ForegroundColor Yellow
                $result = & $executionScript $config $run $Repeat
                Write-Host "Tests completed: Passed=$($result.PassedCount), Failed=$($result.FailedCount), Skipped=$($result.SkippedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { 'Green' } else { 'Red' })

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

        # Show enhanced summary statistics if requested
        if ($ShowSummaryStats) {
            $summaryStats = Get-TestSummaryStatistics -TestResult $result -PerformanceData $performanceData -ShowSlowest 5
            Show-TestSummaryStatistics -Statistics $summaryStats -ShowSlowest -ShowFailurePatterns
        }

        # Display TestName filter summary if filter was applied
        if (-not [string]::IsNullOrWhiteSpace($TestName)) {
            # Parse the patterns to show what was filtered (same logic as Set-PesterTestFilters)
            # Use __SEP__ as delimiter to avoid regex issues with pipe characters
            $normalized = $TestName -replace '\s+or\s+', '__SEP__' -replace '[;,]', '__SEP__'
            $namePatterns = $normalized -split '__SEP__' |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        
            # Count tests that matched the filter (tests that were selected to run)
            # These are the tests that actually ran (passed, failed, skipped, inconclusive)
            # Tests that didn't match the filter are marked as NotRun
            $matchedCount = $result.PassedCount + $result.FailedCount + $result.SkippedCount + 
            $result.InconclusiveCount
        
            # Build pattern summary - show count and first pattern for reference
            # Note: Patterns may contain wildcards that get expanded when displayed, so we show a summary
            $patternSummary = if ($namePatterns.Count -eq 1) {
                "1 pattern"
            }
            else {
                "$($namePatterns.Count) patterns"
            }
        
            # Build message showing filter was applied and how many tests matched
            $message = "TestName filter ($patternSummary) matched $matchedCount test(s)"
            Write-ScriptMessage -Message $message -LogLevel 'Info'
        }

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

        # Save configuration if requested
        if ($SaveConfig) {
            try {
                Write-ScriptMessage -Message "Saving configuration to: $SaveConfig"
            
                # Collect all current parameters
                $configParams = @{}
                foreach ($param in $PSBoundParameters.Keys) {
                    # Skip certain parameters that shouldn't be saved
                    if ($param -notin @('ConfigFile', 'SaveConfig', 'Verbose', 'WhatIf', 'Confirm')) {
                        $configParams[$param] = $PSBoundParameters[$param]
                    }
                }
            
                # Also include variables that might not be in PSBoundParameters but are set
                $paramNames = @('Suite', 'TestName', 'IncludeTag', 'ExcludeTag', 'OutputFormat', 
                    'Coverage', 'CodeCoverageOutputFormat', 'MinimumCoverage', 'ShowCoverageSummary',
                    'Parallel', 'Randomize', 'Repeat', 'Timeout', 'FailOnWarnings', 
                    'SkipRemainingOnFailure', 'CI', 'Quiet', 'TestResultPath', 'CoverageReportPath',
                    'MaxRetries', 'RetryDelaySeconds', 'ExponentialBackoff', 'RetryOnFailure',
                    'SuppressRetryWarnings', 'TrackPerformance', 'TrackMemory', 'TrackCPU',
                    'HealthCheck', 'AnalyzeResults', 'ReportFormat', 'ReportPath', 
                    'IncludeReportDetails', 'Progress', 'MaxParallelThreads', 'StrictMode',
                    'ExcludeCategories', 'OnlyCategories', 'FailFast', 'TestTimeoutSeconds',
                    'GenerateBaseline', 'BaselinePath', 'CompareBaseline', 'BaselineThreshold')
            
                foreach ($paramName in $paramNames) {
                    if (-not $configParams.ContainsKey($paramName) -and (Get-Variable -Name $paramName -Scope Script -ErrorAction SilentlyContinue)) {
                        $value = (Get-Variable -Name $paramName -Scope Script).Value
                        if ($null -ne $value) {
                            $configParams[$paramName] = $value
                        }
                    }
                }
            
                Save-TestConfig -ConfigPath $SaveConfig -Parameters $configParams
            }
            catch {
                Write-ScriptMessage -Message "Failed to save configuration: $($_.Exception.Message)" -LogLevel 'Warning'
                Write-ScriptMessage -Message "Continuing without saving configuration..." -LogLevel 'Info'
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
                        $baselineSeconds = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                            Format-LocaleNumber ([Math]::Round($change.Baseline.TotalSeconds, 2)) -Format 'N2'
                        }
                        else {
                            [Math]::Round($change.Baseline.TotalSeconds, 2).ToString("N2")
                        }
                        $currentSeconds = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                            Format-LocaleNumber ([Math]::Round($change.Current.TotalSeconds, 2)) -Format 'N2'
                        }
                        else {
                            [Math]::Round($change.Current.TotalSeconds, 2).ToString("N2")
                        }
                        $changePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                            Format-LocaleNumber $change.ChangePercent -Format 'N2'
                        }
                        else {
                            $change.ChangePercent.ToString("N2")
                        }
                        Write-ScriptMessage -Message "Overall Duration: ${baselineSeconds}s -> ${currentSeconds}s (${changePercentStr}%) - $status" -LogLevel $(if ($change.IsRegression) { 'Warning' } else { 'Info' })
                    }

                    if ($comparison.Regressions.Count -gt 0) {
                        Write-ScriptMessage -Message "Performance Regressions Detected:" -LogLevel 'Warning'
                        foreach ($regression in $comparison.Regressions) {
                            $changePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                                Format-LocaleNumber $regression.ChangePercent -Format 'N2'
                            }
                            else {
                                $regression.ChangePercent.ToString("N2")
                            }
                            Write-ScriptMessage -Message "  $($regression.TestName): ${changePercentStr}% slower" -LogLevel 'Warning'
                        }
                    }

                    if ($comparison.Improvements.Count -gt 0) {
                        Write-ScriptMessage -Message "Performance Improvements Detected:" -LogLevel 'Info'
                        foreach ($improvement in $comparison.Improvements) {
                            $changePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                                Format-LocaleNumber $improvement.ChangePercent -Format 'N2'
                            }
                            else {
                                $improvement.ChangePercent.ToString("N2")
                            }
                            Write-ScriptMessage -Message "  $($improvement.TestName): ${changePercentStr}% faster" -LogLevel 'Info'
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

        # Determine exit code based on results
        $exitCode = $EXIT_SUCCESS
    
        if ($result.FailedCount -gt 0) {
            $exitCode = $EXIT_TEST_FAILURE
        }
        elseif ($result.TotalCount -eq 0) {
            $exitCode = $EXIT_NO_TESTS_FOUND
        }
        elseif ($MinimumCoverage -and $enableCoverage) {
            # Check coverage threshold if specified
            if ($result.Coverage) {
                $coveragePercent = [Math]::Round($result.Coverage.NumberOfCommandsExecuted / $result.Coverage.NumberOfCommandsAnalyzed * 100, 2)
                if ($coveragePercent -lt $MinimumCoverage) {
                    $exitCode = $EXIT_COVERAGE_FAILURE
                    $coveragePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                        Format-LocaleNumber $coveragePercent -Format 'N2'
                    }
                    else {
                        $coveragePercent.ToString("N2")
                    }
                    $minCoverageStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                        Format-LocaleNumber $MinimumCoverage -Format 'N2'
                    }
                    else {
                        $MinimumCoverage.ToString("N2")
                    }
                    Write-Host "Coverage ${coveragePercentStr}% is below minimum threshold of ${minCoverageStr}%" -ForegroundColor Red
                }
            }
        }
    
        # Exit with appropriate code (unless in watch mode or interactive mode where we return result)
        if (-not $Watch -and -not $Interactive) {
            if ($exitCode -ne $EXIT_SUCCESS) {
                Exit-WithCleanup -ExitCode $exitCode -Message "Test execution completed with failures or issues"
            }
        }
    }
    catch {
        # Re-throw after cleanup
        throw
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
