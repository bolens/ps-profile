<#
scripts/utils/code-quality/modules/TestRunnerHelpers.psm1

.SYNOPSIS
    Helper utilities for the PowerShell profile test runner.

.DESCRIPTION
    Provides helper functions for module imports, dry run execution,
    and other common test runner operations.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'Logging.psm1'
if (Test-Path $loggingModulePath) {
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
    $dryRunConfig = New-PesterConfiguration
    $dryRunConfig.Run.PassThru = $false
    $dryRunConfig.Output.Verbosity = 'Detailed'
    $dryRunConfig.Run.Path = $TestPaths
    $dryRunConfig.Filter.FullName = $Config.Filter.FullName
    $dryRunConfig.Filter.Tag = $Config.Filter.Tag
    $dryRunConfig.Filter.ExcludeTag = $Config.Filter.ExcludeTag

    $dryRunConfig.Run.ScriptBlock = {
        param($Context)
        # This will show discovered tests without running them
        Write-Host "Discovered test file: $($Context.TestFile)"
    }

    Invoke-Pester -Configuration $dryRunConfig
    Write-ScriptMessage -Message "Dry run completed. Use -Verbose for more details."
}

Export-ModuleMember -Function 'Invoke-TestDryRun'

