<#
scripts/utils/code-quality/modules/PesterExecutionConfig.psm1

.SYNOPSIS
    Pester execution configuration utilities.

.DESCRIPTION
    Provides functions for configuring Pester execution options and test filtering.
#>

<#
.SYNOPSIS
    Configures execution options for Pester.

.DESCRIPTION
    Applies parallel execution and failure-handling options to a Pester
    configuration object.

.PARAMETER Config
    Pester configuration object to update.

.PARAMETER Parallel
    Maximum parallel thread count. Values greater than zero enable parallel runs.

.PARAMETER Randomize
    Reserved for runner-level test file shuffling.

.PARAMETER Timeout
    Optional per-test timeout in seconds.

.PARAMETER FailOnWarnings
    Reserved for runner-level warning preference handling.

.PARAMETER SkipRemainingOnFailure
    Stops remaining tests in a block after the first failure.

.EXAMPLE
    Set-PesterExecutionOptions -Config $config -Parallel 4
#>
function Set-PesterExecutionOptions {
    param(
        [PesterConfiguration]$Config,
        [int]$Parallel,
        [switch]$Randomize,
        [Nullable[int]]$Timeout,
        [switch]$FailOnWarnings,
        [switch]$SkipRemainingOnFailure,
        [string]$TestSupportPath,
        [string]$TestsDir
    )

    # Configure parallel execution
    if ($Parallel -and $Parallel -gt 0) {
        if ($Config.Run.PSObject.Properties.Name -contains 'Parallel') {
            $Config.Run.Parallel = $true
        }
        if ($Config.Run.PSObject.Properties.Name -contains 'MaximumThreadCount') {
            $Config.Run.MaximumThreadCount = $Parallel
        }

        # Parallel workers run in isolated runspaces; load TestSupport in each worker.
        if ($TestSupportPath -and -not [string]::IsNullOrWhiteSpace($TestSupportPath) -and (Test-Path -LiteralPath $TestSupportPath)) {
            $supportPath = $TestSupportPath
            $testsDirectory = if ($TestsDir -and -not [string]::IsNullOrWhiteSpace($TestsDir)) {
                $TestsDir
            }
            else {
                Split-Path -Parent $TestSupportPath
            }

            if ($Config.Run.PSObject.Properties.Name -contains 'Initialization') {
                $Config.Run.Initialization = {
                    $ErrorActionPreference = 'Stop'
                    $ConfirmPreference = 'None'
                    $global:ConfirmPreference = 'None'
                    if (-not $global:PSDefaultParameterValues) {
                        $global:PSDefaultParameterValues = @{}
                    }
                    $global:PSDefaultParameterValues['Remove-Item:Confirm'] = $false
                    $global:PSDefaultParameterValues['Remove-Item:Force'] = $true
                    $global:PSDefaultParameterValues['Remove-Item:Recurse'] = $true

                    $env:PS_PROFILE_TEST_SUPPORT_PATH = $using:supportPath
                    $env:PS_PROFILE_TESTS_DIR = $using:testsDirectory

                    $originalPSScriptRoot = $PSScriptRoot
                    $PSScriptRoot = $using:testsDirectory
                    try {
                        . $using:supportPath
                    }
                    finally {
                        $PSScriptRoot = $originalPSScriptRoot
                    }
                }
            }
        }
    }

    # Randomization is handled at the runner level by shuffling discovered test
    # file paths before execution (Pester 5 has no Run.Randomize option).

    # Configure timeout
    # if ($null -ne $Timeout) {
    #     $Config.Run.TestTimeout = $Timeout
    # }

    # Configure failure handling
    if ($SkipRemainingOnFailure) {
        $Config.Run.SkipRemainingOnFailure = 'Block'
    }

    # FailOnWarnings is handled at the runner level by setting $WarningPreference
    # to Stop for the duration of test execution.

    return $Config
}

<#
.SYNOPSIS
    Applies test filtering to Pester configuration.

.DESCRIPTION
    Configures test name and tag filters on a Pester configuration object.

.PARAMETER Config
    Pester configuration object to update.

.PARAMETER TestName
    Test name pattern or list of patterns to execute.

.PARAMETER IncludeTag
    Tags that must be present for a test to run.

.PARAMETER ExcludeTag
    Tags that exclude matching tests from execution.

.EXAMPLE
    Set-PesterTestFilters -Config $config -IncludeTag Unit
#>
function Set-PesterTestFilters {
    param(
        [PesterConfiguration]$Config,
        [string]$TestName,
        [string[]]$IncludeTag,
        [string[]]$ExcludeTag
    )

    if (-not [string]::IsNullOrWhiteSpace($TestName)) {
        # Parse TestName patterns separated by " or ", commas, or semicolons
        # Normalize all separators to a single delimiter, then split
        # This handles: "pattern1 or pattern2", "pattern1, pattern2", "pattern1; pattern2", or mixed
        # Use __SEP__ as delimiter to avoid regex issues with pipe characters
        # Replace semicolons and commas with separator
        $normalized = $TestName -replace '\s+or\s+', '__SEP__' -replace ';', '__SEP__' -replace ',', '__SEP__'
        $namePatterns = $normalized -split '__SEP__' |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if ($namePatterns) {
            $Config.Filter.FullName = $namePatterns
        }
    }

    # Configure tag filtering
    if ($IncludeTag) {
        $Config.Filter.Tag = $IncludeTag
    }

    if ($ExcludeTag) {
        $Config.Filter.ExcludeTag = $ExcludeTag
    }

    return $Config
}

Export-ModuleMember -Function @(
    'Set-PesterExecutionOptions',
    'Set-PesterTestFilters'
)

