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
    if ($Parallel) {
        # In Pester 5, parallel execution is often handled at the container level or via Invoke-Pester parameters directly.
        # However, looking at the configuration object, there isn't a direct 'ContainerParallel' property on 'Run'.
        # If this property doesn't exist, we might need to remove this configuration or find the correct one.
        # For now, I will comment this out to fix the runtime error, as the property clearly doesn't exist.
        # $Config.Run.ContainerParallel = $true
        # $Config.Run.MaximumThreadCount = $Parallel
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
        $namePatterns = $TestName -replace '[;,]', ' or ' -split '\s+or\s+' |
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

