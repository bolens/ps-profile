<#
scripts/lib/FragmentErrorHandling.psm1

.SYNOPSIS
    Fragment error handling utilities.

.DESCRIPTION
    Provides standardized error handling for fragment loading and execution.
    Ensures consistent error reporting and allows fragments to fail gracefully
    without stopping the entire profile load.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import Logging for consistent output
$loggingModulePath = Join-Path $PSScriptRoot 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Safely executes a fragment with error handling.

.DESCRIPTION
    Wraps fragment execution in try-catch with standardized error handling.
    Checks for warning suppression and uses Write-ProfileError if available.

.PARAMETER FragmentName
    The name of the fragment being executed (for error context).

.PARAMETER FragmentPath
    The path to the fragment file.

.PARAMETER ScriptBlock
    Optional script block to execute. If not provided, dot-sources the fragment file.

.PARAMETER SuppressWarnings
    If specified, suppresses warnings for this fragment.

.OUTPUTS
    System.Boolean. $true if execution succeeded, $false otherwise.

.EXAMPLE
    $success = Invoke-FragmentSafely -FragmentName '11-git' -FragmentPath $fragmentPath
    if (-not $success) {
        Write-Warning "Failed to load git fragment"
    }
#>
function Invoke-FragmentSafely {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentName,

        [Parameter(Mandatory)]
        [string]$FragmentPath,

        [scriptblock]$ScriptBlock,

        [switch]$SuppressWarnings
    )

    $errorContext = @{
        FragmentName = $FragmentName
        FragmentPath = $FragmentPath
        Timestamp    = Get-Date
    }

    try {
        if ($ScriptBlock) {
            & $ScriptBlock
        }
        else {
            if (-not (Test-Path $FragmentPath -ErrorAction SilentlyContinue)) {
                $errorContext.ErrorType = 'FileNotFound'
                $errorMessage = "Fragment file not found: $FragmentPath"
                
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                        Write-ScriptMessage -Message $errorMessage -IsWarning
                    }
                    else {
                        Write-Warning $errorMessage
                    }
                }
                return $false
            }

            # Validate file is readable before attempting to load
            try {
                $fileInfo = Get-Item $FragmentPath -ErrorAction Stop
                if (-not $fileInfo) {
                    throw "Unable to get file information"
                }
            }
            catch {
                $errorContext.ErrorType = 'FileAccessError'
                $errorMessage = "Cannot access fragment file '$FragmentPath': $($_.Exception.Message)"
                
                if (-not $env:PS_PROFILE_DEBUG) {
                    return $false
                }
                
                if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                    Write-ScriptMessage -Message $errorMessage -IsError
                }
                else {
                    Write-Host $errorMessage -ForegroundColor Red
                }
                return $false
            }

            # Attempt to load the fragment
            try {
                $null = . $FragmentPath
            }
            catch {
                # Re-throw to be caught by outer catch block
                throw
            }
        }
        return $true
    }
    catch {
        $errorContext.ErrorType = $_.Exception.GetType().Name
        $errorContext.LineNumber = $_.InvocationInfo.ScriptLineNumber
        $errorContext.PositionMessage = $_.InvocationInfo.PositionMessage
        $errorContext.Exception = $_.Exception

        $suppressFragmentWarning = $SuppressWarnings

        # Check if warning should be suppressed
        if (-not $suppressFragmentWarning -and (Get-Command Test-FragmentWarningSuppressed -ErrorAction SilentlyContinue)) {
            try {
                $suppressFragmentWarning = Test-FragmentWarningSuppressed -FragmentName $FragmentName
            }
            catch {
                $suppressFragmentWarning = $false
            }
        }

        $errorMessage = "Failed to load profile fragment '$FragmentName': $($_.Exception.Message)"
        
        # Add line number context if available
        if ($errorContext.LineNumber -gt 0) {
            $errorMessage += " (Line: $($errorContext.LineNumber))"
        }

        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                Write-ScriptMessage -Message $errorMessage -IsError
            }
            else {
                Write-Host $errorMessage -ForegroundColor Red
            }
            
            # Provide additional context in debug mode
            if ($errorContext.PositionMessage) {
                Write-Host "Position: $($errorContext.PositionMessage)" -ForegroundColor DarkGray
            }
        }

        # Use Write-ProfileError if available
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: $FragmentName" -Category 'Fragment'
        }
        elseif (-not $suppressFragmentWarning) {
            Write-Warning $errorMessage
        }

        return $false
    }
}

<#
.SYNOPSIS
    Writes a fragment error with context.

.DESCRIPTION
    Provides a standardized way to write fragment-related errors with proper
    context and formatting.

.PARAMETER ErrorRecord
    The error record to write.

.PARAMETER FragmentName
    The name of the fragment where the error occurred.

.PARAMETER Context
    Optional additional context information.

.EXAMPLE
    try {
        # Fragment code
    }
    catch {
        Write-FragmentError -ErrorRecord $_ -FragmentName '11-git' -Context 'Git initialization'
    }
#>
function Write-FragmentError {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory)]
        [string]$FragmentName,

        [string]$Context
    )

    $errorMessage = "Fragment '$FragmentName'"
    if ($Context) {
        $errorMessage += " ($Context)"
    }
    $errorMessage += ": $($ErrorRecord.Exception.Message)"

    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $ErrorRecord -Context "Fragment: $FragmentName" -Category 'Fragment'
    }
    else {
        Write-Error -Message $errorMessage -ErrorRecord $ErrorRecord
    }
}

<#
.SYNOPSIS
    Gets detailed error information for a fragment error.

.DESCRIPTION
    Extracts comprehensive error information from an error record,
    including stack trace, invocation info, and error type details.

.PARAMETER ErrorRecord
    The error record to analyze.

.PARAMETER FragmentName
    The name of the fragment where the error occurred.

.OUTPUTS
    PSCustomObject with detailed error information.

.EXAMPLE
    try {
        # Fragment code
    }
    catch {
        $errorInfo = Get-FragmentErrorInfo -ErrorRecord $_ -FragmentName '11-git'
        Write-Host "Error type: $($errorInfo.ErrorType)"
    }
#>
function Get-FragmentErrorInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory)]
        [string]$FragmentName
    )

    $errorInfo = [PSCustomObject]@{
        FragmentName          = $FragmentName
        ErrorType             = $ErrorRecord.Exception.GetType().Name
        ErrorMessage          = $ErrorRecord.Exception.Message
        ScriptName            = $ErrorRecord.InvocationInfo.ScriptName
        LineNumber            = $ErrorRecord.InvocationInfo.ScriptLineNumber
        ColumnNumber          = $ErrorRecord.InvocationInfo.PositionMessage
        CommandName           = $ErrorRecord.InvocationInfo.InvocationName
        FullyQualifiedErrorId = $ErrorRecord.FullyQualifiedErrorId
        Timestamp             = Get-Date
    }

    # Add inner exception info if available
    if ($ErrorRecord.Exception.InnerException) {
        $errorInfo | Add-Member -MemberType NoteProperty -Name 'InnerException' -Value $ErrorRecord.Exception.InnerException.Message
        $errorInfo | Add-Member -MemberType NoteProperty -Name 'InnerExceptionType' -Value $ErrorRecord.Exception.InnerException.GetType().Name
    }

    # Add stack trace if available
    if ($ErrorRecord.ScriptStackTrace) {
        $errorInfo | Add-Member -MemberType NoteProperty -Name 'ScriptStackTrace' -Value $ErrorRecord.ScriptStackTrace
    }

    return $errorInfo
}

Export-ModuleMember -Function @(
    'Invoke-FragmentSafely',
    'Write-FragmentError',
    'Get-FragmentErrorInfo'
)

