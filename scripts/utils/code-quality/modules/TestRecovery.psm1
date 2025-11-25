<#
scripts/utils/code-quality/modules/TestRecovery.psm1

.SYNOPSIS
    Test execution recovery utilities.

.DESCRIPTION
    Provides functions for recovering from common test execution failures.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Attempts to recover from common test execution failures.

.DESCRIPTION
    Analyzes the error and attempts automatic recovery for known transient issues
    such as temporary file locks, network timeouts, or resource constraints.

.PARAMETER Exception
    The exception that occurred during test execution.

.PARAMETER Context
    Additional context about the failure (test name, file, etc.).

.OUTPUTS
    Recovery action result or $null if no recovery possible
#>
function Invoke-TestExecutionRecovery {
    param(
        [Parameter(Mandatory)]
        [Exception]$Exception,

        [hashtable]$Context = @{}
    )

    $errorMessage = $Exception.Message.ToLower()

    # Recovery for common transient failures
    if ($errorMessage -match 'cannot access the file.*because it is being used by another process') {
        Write-ScriptMessage -Message "Detected file lock issue, attempting recovery..." -LogLevel 'Info'
        try {
            # Wait a bit and retry
            Start-Sleep -Seconds 2
            return @{ Action = 'Retry'; Message = 'Retried after file lock' }
        }
        catch {
            return $null
        }
    }

    if ($errorMessage -match 'network|connection|timeout' -and $errorMessage -notmatch 'test.*timeout') {
        Write-ScriptMessage -Message "Detected network issue, attempting recovery..." -LogLevel 'Info'
        try {
            # Brief wait for network recovery
            Start-Sleep -Seconds 1
            return @{ Action = 'Retry'; Message = 'Retried after network issue' }
        }
        catch {
            return $null
        }
    }

    if ($errorMessage -match 'out of memory|insufficient memory') {
        Write-ScriptMessage -Message "Detected memory issue, suggesting cleanup..." -LogLevel 'Warning'
        try {
            # Force garbage collection
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
            return @{ Action = 'Retry'; Message = 'Performed garbage collection' }
        }
        catch {
            return $null
        }
    }

    if ($errorMessage -match 'permission|access denied|unauthorized') {
        Write-ScriptMessage -Message "Detected permission issue, cannot automatically recover" -LogLevel 'Error'
        return @{ Action = 'Fail'; Message = 'Permission error requires manual intervention' }
    }

    # No automatic recovery possible
    return $null
}

Export-ModuleMember -Function Invoke-TestExecutionRecovery

