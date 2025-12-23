<#
scripts/utils/code-quality/modules/PesterConfig.psm1

.SYNOPSIS
    Pester configuration utilities for the PowerShell profile test runner.

.DESCRIPTION
    Provides functions to configure Pester test execution with various options
    including output formatting, parallel execution, coverage, and filtering.
    
    This module defines New-PesterTestConfiguration which uses functions from specialized submodules:
    - PesterOutputConfig.psm1: Output verbosity, CI optimizations, test results
    - PesterCoverageConfig.psm1: Code coverage configuration
    - PesterExecutionConfig.psm1: Execution options and test filtering
    
    Note: Import submodules directly to use their functions - this module only exports New-PesterTestConfiguration.
#>

# Import specialized submodules
$outputConfigPath = Join-Path $PSScriptRoot 'PesterOutputConfig.psm1'
$coverageConfigPath = Join-Path $PSScriptRoot 'PesterCoverageConfig.psm1'
$executionConfigPath = Join-Path $PSScriptRoot 'PesterExecutionConfig.psm1'

if ($outputConfigPath -and -not [string]::IsNullOrWhiteSpace($outputConfigPath) -and (Test-Path -LiteralPath $outputConfigPath)) {
    Import-Module $outputConfigPath -DisableNameChecking -ErrorAction SilentlyContinue
}
if ($coverageConfigPath -and -not [string]::IsNullOrWhiteSpace($coverageConfigPath) -and (Test-Path -LiteralPath $coverageConfigPath)) {
    Import-Module $coverageConfigPath -DisableNameChecking -ErrorAction SilentlyContinue
}
if ($executionConfigPath -and -not [string]::IsNullOrWhiteSpace($executionConfigPath) -and (Test-Path -LiteralPath $executionConfigPath)) {
    Import-Module $executionConfigPath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Creates and configures a Pester configuration object.

.DESCRIPTION
    Builds a comprehensive Pester configuration based on the provided parameters,
    handling output verbosity, CI optimizations, test results, coverage, parallel
    execution, and various other test execution options.

.PARAMETER OutputFormat
    Controls the verbosity of test output.

.PARAMETER CI
    Enable CI mode optimizations.

.PARAMETER OutputPath
    Path to save test results.

.PARAMETER TestResultPath
    Directory for test result files.

.PARAMETER Coverage
    Enable code coverage reporting.

.PARAMETER ShowCoverageSummary
    Show coverage summary.

.PARAMETER CodeCoverageOutputFormat
    Format for coverage output.

.PARAMETER CoverageReportPath
    Directory for coverage reports.

.PARAMETER MinimumCoverage
    Minimum coverage percentage.

.PARAMETER Parallel
    Enable parallel execution.

.PARAMETER Randomize
    Randomize test order.

.PARAMETER Timeout
    Test execution timeout.

.PARAMETER FailOnWarnings
    Treat warnings as failures.

.PARAMETER SkipRemainingOnFailure
    Stop on first failure.

.PARAMETER Quiet
    Enable quiet mode.

.PARAMETER Verbose
    Enable verbose mode.

.PARAMETER ProfileDir
    Path to profile directory for coverage.

.PARAMETER RepoRoot
    Repository root path.

.OUTPUTS
    PesterConfiguration
#>
function New-PesterTestConfiguration {
    param(
        [ValidateSet('Normal', 'Detailed', 'Minimal', 'None')]
        [string]$OutputFormat = 'Detailed',

        [switch]$CI,

        [string]$OutputPath,

        [string]$TestResultPath,

        [switch]$Coverage,

        [switch]$ShowCoverageSummary,

        [ValidateSet('JaCoCo', 'CoverageGutters', 'Cobertura')]
        [string]$CodeCoverageOutputFormat = 'JaCoCo',

        [string]$CoverageReportPath,

        [ValidateRange(0, 100)]
        [int]$MinimumCoverage,

        [ValidateRange(1, 100)]
        [int]$Parallel,

        [switch]$Randomize,

        [ValidateRange(1, [int]::MaxValue)]
        [Nullable[int]]$Timeout, [switch]$FailOnWarnings,

        [switch]$SkipRemainingOnFailure,

        [switch]$Quiet,

        [switch]$Verbose,

        [string]$ProfileDir,

        [string]$RepoRoot,

        [string[]]$TestPaths
    )

    $config = New-PesterConfiguration
    $config.Run.PassThru = $true
    $config.Run.Exit = $false

    # Configure output verbosity
    $verbosityParams = @{
        Config       = $config
        OutputFormat = $OutputFormat
    }
    if ($CI) { $verbosityParams['CI'] = $true }
    if ($Quiet) { $verbosityParams['Quiet'] = $true }
    if ($Verbose) { $verbosityParams['Verbose'] = $true }
    $config = Set-PesterOutputVerbosity @verbosityParams

    # Configure CI optimizations
    if ($CI) {
        $config = Set-PesterCIOptimizations -Config $config -OutputPath $OutputPath -Coverage:$Coverage -RepoRoot $RepoRoot
    }

    # Configure test results
    $config = Set-PesterTestResults -Config $config -OutputPath $OutputPath -TestResultPath $TestResultPath

    # Configure code coverage (pass TestPaths for targeted coverage)
    $coverageParams = @{
        Config                   = $config
        Coverage                 = $Coverage
        ShowCoverageSummary      = $ShowCoverageSummary
        CodeCoverageOutputFormat = $CodeCoverageOutputFormat
        CoverageReportPath       = $CoverageReportPath
        MinimumCoverage          = $MinimumCoverage
        ProfileDir               = $ProfileDir
        RepoRoot                 = $RepoRoot
    }
    if ($TestPaths) {
        $coverageParams['TestPaths'] = $TestPaths
    }
    $config = Set-PesterCodeCoverage @coverageParams

    # Configure execution options
    $executionOptions = @{
        Config                 = $Config
        Parallel               = $Parallel
        Randomize              = $Randomize
        FailOnWarnings         = $FailOnWarnings
        SkipRemainingOnFailure = $SkipRemainingOnFailure
    }

    if ($null -ne $Timeout) {
        $executionOptions['Timeout'] = $Timeout
    }

    $Config = Set-PesterExecutionOptions @executionOptions

    return $config
}

# Import submodules for use by New-PesterTestConfiguration
# Note: Submodules are imported directly in run-pester.ps1, so this import is for internal use only
# Functions from submodules are NOT re-exported - import submodules directly to use them
# - PesterOutputConfig.psm1: Set-PesterOutputVerbosity, Set-PesterCIOptimizations, Set-PesterTestResults
# - PesterCoverageConfig.psm1: Set-PesterCodeCoverage
# - PesterExecutionConfig.psm1: Set-PesterExecutionOptions, Set-PesterTestFilters

# Only export this module's own function (not a barrel file)
Export-ModuleMember -Function 'New-PesterTestConfiguration'
