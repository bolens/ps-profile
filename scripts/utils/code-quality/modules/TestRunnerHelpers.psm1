<#
scripts/utils/code-quality/modules/TestRunnerHelpers.psm1

.SYNOPSIS
    Helper utilities for the PowerShell profile test runner.

.DESCRIPTION
    Provides helper functions for module imports, dry run execution,
    and other common test runner operations.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Performs a dry run of test discovery without execution.

.DESCRIPTION
    Shows which tests would be run without actually executing them.
    Useful for validating test selection and configuration.

.PARAMETER Config
    The Pester configuration object.

.PARAMETER TestPaths
    Array of test paths to discover.

.OUTPUTS
    None
#>
function Invoke-TestDryRun {
    param(
        [Parameter(Mandatory)]
        $Config,

        [Parameter(Mandatory)]
        [string[]]$TestPaths
    )

    Write-ScriptMessage -Message "DRY RUN MODE: Showing test discovery without execution"

    # Create a separate configuration for dry run
    # In Pester 5, Path must be set on config object (cannot use both -Configuration and -Path together)
    $dryRunConfig = New-PesterConfiguration
    $dryRunConfig.Run.PassThru = $false
    $dryRunConfig.Output.Verbosity = 'Detailed'
    $dryRunConfig.Run.Path = $TestPaths
    if ($Config.Filter.FullName.Value) {
        $dryRunConfig.Filter.FullName = $Config.Filter.FullName.Value
    }
    if ($Config.Filter.Tag.Value) {
        $dryRunConfig.Filter.Tag = $Config.Filter.Tag.Value
    }
    if ($Config.Filter.ExcludeTag.Value) {
        $dryRunConfig.Filter.ExcludeTag = $Config.Filter.ExcludeTag.Value
    }

    $dryRunConfig.Run.ScriptBlock = {
        param($Context)
        # This will show discovered tests without running them
        Write-Host "Discovered test file: $($Context.TestFile)"
    }

    # Use only -Configuration (path is set in config, cannot use both -Configuration and -Path)
    Invoke-Pester -Configuration $dryRunConfig
    Write-ScriptMessage -Message "Dry run completed. Use -Verbose for more details."
}

Export-ModuleMember -Function 'Invoke-TestDryRun'

