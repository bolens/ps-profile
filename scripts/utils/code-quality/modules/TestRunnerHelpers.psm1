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
        $Config,

        [Parameter(Mandatory)]
        [string[]]$TestPaths
    )

    Write-ScriptMessage -Message "DRY RUN MODE: Showing test discovery without execution"

    foreach ($testPath in @($TestPaths)) {
        if ([string]::IsNullOrWhiteSpace($testPath)) {
            continue
        }

        if (Test-Path -LiteralPath $testPath -PathType Container) {
            $files = Get-ChildItem -Path $testPath -Filter '*.tests.ps1' -Recurse -File -ErrorAction SilentlyContinue
            foreach ($file in @($files)) {
                Write-Host "Discovered test file: $($file.FullName)"
            }
        }
        else {
            Write-Host "Discovered test file: $testPath"
        }
    }

    Write-ScriptMessage -Message "Dry run completed. Use -Verbose for more details."
}

Export-ModuleMember -Function 'Invoke-TestDryRun'

