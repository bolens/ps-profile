<#
scripts/utils/code-quality/modules/TestErrorRecovery.psm1

.SYNOPSIS
    Enhanced error recovery utilities for test execution.

.DESCRIPTION
    Provides intelligent error recovery mechanisms including automatic
    cleanup, resource management, and graceful degradation.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Implements enhanced error recovery for test execution.

.DESCRIPTION
    Provides intelligent error recovery mechanisms including automatic
    cleanup, resource management, and graceful degradation.

.PARAMETER ScriptBlock
    The script block to execute with error recovery.

.PARAMETER MaxRecoveryAttempts
    Maximum number of recovery attempts.

.PARAMETER RecoveryActions
    Array of recovery actions to attempt.

.OUTPUTS
    Execution result with recovery information
#>
function Invoke-WithErrorRecovery {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$MaxRecoveryAttempts = 3,

        [scriptblock[]]$RecoveryActions
    )

    $attempt = 0
    $lastException = $null
    $recoveryHistory = @()

    do {
        $attempt++
        try {
            $result = & $ScriptBlock
            return @{
                Success         = $true
                Result          = $result
                Attempts        = $attempt
                RecoveryHistory = $recoveryHistory
            }
        }
        catch {
            $lastException = $_
            $recoveryHistory += @{
                Attempt   = $attempt
                Exception = $_.Exception.Message
                Timestamp = Get-Date
            }

            if ($attempt -le $MaxRecoveryAttempts -and $RecoveryActions -and $RecoveryActions.Count -ge $attempt) {
                Write-ScriptMessage -Message "Attempting error recovery $attempt of $MaxRecoveryAttempts" -LogLevel 'Warning'

                try {
                    & $RecoveryActions[$attempt - 1]
                    Start-Sleep -Seconds 1  # Brief pause before retry
                }
                catch {
                    Write-ScriptMessage -Message "Recovery action failed: $($_.Exception.Message)" -LogLevel 'Warning'
                }
            }
        }
    } while ($attempt -le $MaxRecoveryAttempts)

    return @{
        Success         = $false
        Result          = $null
        Attempts        = $attempt
        LastException   = $lastException
        RecoveryHistory = $recoveryHistory
    }
}

Export-ModuleMember -Function Invoke-WithErrorRecovery

