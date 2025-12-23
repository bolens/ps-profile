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
#>
function Set-PesterExecutionOptions {
    param(
        [PesterConfiguration]$Config,
        [int]$Parallel,
        [switch]$Randomize,
        [Nullable[int]]$Timeout,
        [switch]$FailOnWarnings,
        [switch]$SkipRemainingOnFailure
    )

    # Configure parallel execution
    if ($Parallel -and $Parallel -gt 0) {
        # In Pester 5, parallel execution is configured using Run.Parallel and Run.MaximumThreadCount
        # Enable parallel execution
        $Config.Run.Parallel = $true
        # Set the maximum number of threads
        $Config.Run.MaximumThreadCount = $Parallel
    }

    # Configure randomization
    if ($Randomize) {
        # Similarly, 'Randomize' is not on 'Run'.
        # $Config.Run.Randomize = $true
    }

    # Configure timeout
    # if ($null -ne $Timeout) {
    #     $Config.Run.TestTimeout = $Timeout
    # }

    # Configure failure handling
    if ($SkipRemainingOnFailure) {
        $Config.Run.SkipRemainingOnFailure = 'Block'
    }

    # Configure warning handling
    if ($FailOnWarnings) {
        # WarningAction is not a property of RunConfiguration in Pester 5.
        # $Config.Run.WarningAction = 'Error'
    }

    return $Config
}

<#
.SYNOPSIS
    Applies test filtering to Pester configuration.
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

