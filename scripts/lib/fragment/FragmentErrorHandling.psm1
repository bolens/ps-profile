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

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$parentDir = Split-Path -Parent $PSScriptRoot
$safeImportModulePath = Join-Path $parentDir 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Logging for consistent output
$loggingModulePath = Join-Path $PSScriptRoot 'Logging.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $loggingModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
        Import-Module $loggingModulePath -ErrorAction SilentlyContinue
    }
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
        [ValidateNotNullOrEmpty()]
        [string]$FragmentName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentPath,

        [scriptblock]$ScriptBlock,

        [switch]$SuppressWarnings
    )

    # Cache command existence checks to avoid repeated Get-Command calls
    # Use Test-CachedCommand if available for better performance, otherwise use Test-HasCommand
    $hasWriteScriptMessage = $false
    $hasTestFragmentWarningSuppressed = $false
    $hasWriteProfileError = $false

    # Fast check: Test function provider first to avoid Get-Command overhead
    $useCachedCommand = (Test-Path 'Function:\Test-CachedCommand' -ErrorAction SilentlyContinue) -or
    (Test-Path 'Function:\global:Test-CachedCommand' -ErrorAction SilentlyContinue)

    if ($useCachedCommand) {
        $hasWriteScriptMessage = Test-CachedCommand -Name 'Write-ScriptMessage'
        $hasTestFragmentWarningSuppressed = Test-CachedCommand -Name 'Test-FragmentWarningSuppressed'
        $hasWriteProfileError = Test-CachedCommand -Name 'Write-ProfileError'
    }
    else {
        # Fallback: Direct Get-Command checks (only if Test-CachedCommand unavailable)
        $hasWriteScriptMessage = (Get-Command 'Write-ScriptMessage' -ErrorAction SilentlyContinue) -ne $null
        $hasTestFragmentWarningSuppressed = (Get-Command 'Test-FragmentWarningSuppressed' -ErrorAction SilentlyContinue) -ne $null
        $hasWriteProfileError = (Get-Command 'Write-ProfileError' -ErrorAction SilentlyContinue) -ne $null
    }

    $errorContext = @{
        FragmentName = $FragmentName
        FragmentPath = $FragmentPath
    }

    try {
        if ($ScriptBlock) {
            & $ScriptBlock
        }
        else {
            if (-not ($FragmentPath -and -not [string]::IsNullOrWhiteSpace($FragmentPath) -and (Test-Path -LiteralPath $FragmentPath -ErrorAction SilentlyContinue))) {
                $errorContext.ErrorType = 'FileNotFound'
                $errorMessage = "Fragment file not found: $FragmentPath"
                
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message $errorMessage -OperationName 'fragment-error-handling.load' -Context @{
                                FragmentName = $FragmentName
                                FragmentPath = $FragmentPath
                                ErrorType    = 'FileNotFound'
                            }
                        }
                        elseif ($hasWriteScriptMessage) {
                            Write-ScriptMessage -Message "[fragment-error-handling.load] $errorMessage" -IsWarning
                        }
                        else {
                            Write-Warning "[fragment-error-handling.load] $errorMessage"
                        }
                    }
                    # Level 3: Log detailed file not found information
                    if ($debugLevel -ge 3) {
                        Write-Verbose "[fragment-error-handling.load] File not found details - FragmentName: $FragmentName, FragmentPath: $FragmentPath"
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
                
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'fragment-error-handling.load' -Context @{
                                FragmentName = $FragmentName
                                FragmentPath = $FragmentPath
                                ErrorType    = 'FileAccessError'
                            }
                        }
                        elseif ($hasWriteScriptMessage) {
                            Write-ScriptMessage -Message "[fragment-error-handling.load] $errorMessage" -IsError
                        }
                        else {
                            Write-Error "[fragment-error-handling.load] $errorMessage"
                        }
                    }
                    # Level 3: Log detailed file access error information
                    if ($debugLevel -ge 3) {
                        Write-Host "  [fragment-error-handling.load] File access error details - FragmentName: $FragmentName, FragmentPath: $FragmentPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                    }
                }
                else {
                    return $false
                }
                return $false
            }

            # Attempt to load the fragment
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [fragment-error-handling.load] Loading fragment: $FragmentName from $FragmentPath" -ForegroundColor DarkGray
            }
            try {
                $null = . $FragmentPath
                # Level 2: Log successful fragment load
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                    Write-Host "  [fragment-error-handling.load] Successfully loaded fragment: $FragmentName" -ForegroundColor DarkGray
                }
            }
            catch {
                # Re-throw to be caught by outer catch block
                throw
            }
        }
        # Level 2: Log successful scriptblock execution
        if ($ScriptBlock) {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[fragment-error-handling.load] Successfully executed scriptblock for fragment: $FragmentName"
            }
        }
        return $true
    }
    catch {
        # Only call Get-Date when we actually need it (in error case)
        $errorContext.Timestamp = Get-Date
        $errorContext.ErrorType = $_.Exception.GetType().Name
        $errorContext.LineNumber = $_.InvocationInfo.ScriptLineNumber
        $errorContext.PositionMessage = $_.InvocationInfo.PositionMessage
        $errorContext.Exception = $_.Exception

        $suppressFragmentWarning = $SuppressWarnings

        # Check if warning should be suppressed
        if (-not $suppressFragmentWarning -and $hasTestFragmentWarningSuppressed) {
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

        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'fragment-error-handling.load' -Context @{
                        FragmentName    = $FragmentName
                        FragmentPath    = $FragmentPath
                        ErrorType       = $errorContext.ErrorType
                        LineNumber      = $errorContext.LineNumber
                        SuppressWarning = $suppressFragmentWarning
                    }
                }
                elseif ($hasWriteScriptMessage) {
                    Write-ScriptMessage -Message "[fragment-error-handling.load] $errorMessage" -IsError
                }
                else {
                    Write-Error "[fragment-error-handling.load] $errorMessage"
                }
            }
            
            # Provide additional context in verbose debug mode
            if ($debugLevel -ge 2 -and $errorContext.PositionMessage) {
                Write-Host "  [fragment-error-handling.load] Position: $($errorContext.PositionMessage)" -ForegroundColor DarkGray
            }
            
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [fragment-error-handling.load] Error details - FragmentName: $FragmentName, ErrorType: $($errorContext.ErrorType), LineNumber: $($errorContext.LineNumber), Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                if ($errorContext.PositionMessage) {
                    Write-Host "  [fragment-error-handling.load] Position details: $($errorContext.PositionMessage)" -ForegroundColor DarkGray
                }
            }

            # Use Write-ProfileError if available (legacy support)
            if ($hasWriteProfileError -and $debugLevel -ge 1) {
                try {
                    Write-ProfileError -ErrorRecord $_ -Context "Fragment: $FragmentName" -Category 'Fragment'
                }
                catch {
                    # Silently ignore if Write-ProfileError fails
                }
            }
            elseif (-not $suppressFragmentWarning -and $debugLevel -ge 1) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message $errorMessage -OperationName 'fragment-error-handling.load' -Context @{
                        FragmentName = $FragmentName
                        FragmentPath = $FragmentPath
                        ErrorType    = $errorContext.ErrorType
                        LineNumber   = $errorContext.LineNumber
                    }
                }
                else {
                    Write-Warning $errorMessage
                }
            }

            return $false
        }
        elseif (-not $suppressFragmentWarning) {
            # Even without debug, show warning if not suppressed
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message $errorMessage -OperationName 'fragment-error-handling.load' -Context @{
                    FragmentName = $FragmentName
                    FragmentPath = $FragmentPath
                    ErrorType    = $errorContext.ErrorType
                }
            }
            else {
                Write-Warning $errorMessage
            }
            return $false
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
        [ValidateNotNullOrEmpty()]
        [string]$FragmentName,

        [string]$Context
    )

    $errorMessage = "Fragment '$FragmentName'"
    if ($Context) {
        $errorMessage += " ($Context)"
    }
    $errorMessage += ": $($ErrorRecord.Exception.Message)"

    # Create error record for writing
    $errorRecordToWrite = [System.Management.Automation.ErrorRecord]::new(
        [System.Exception]::new($errorMessage),
        'FragmentError',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null
    )

    # Wrap all error writing in try-catch to prevent any exceptions from propagating
    # Tests expect this function to not throw, even when writing errors
    try {
        # Always use $PSCmdlet.WriteError() which does NOT throw, even with $ErrorActionPreference = 'Stop'
        # This allows tests to verify error was written without exception
        if ($PSCmdlet) {
            # $PSCmdlet.WriteError() never throws, it only writes to the error stream
            # But wrap in try-catch just in case
            try {
                $PSCmdlet.WriteError($errorRecordToWrite)
            }
            catch {
                # Silently ignore any exceptions from WriteError
            }
        }
        else {
            # If not in cmdlet context, try Write-ProfileError first, then fall back to Write-Error
            # But we need to suppress exceptions since Write-Error can throw
            $errorWritten = $false
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                try {
                    $contextValue = if ($Context) { "${Context}: Fragment: $FragmentName" } else { "Fragment: $FragmentName" }
                    Write-ProfileError -ErrorRecord $ErrorRecord -Context $contextValue -Category 'Fragment' -ErrorAction SilentlyContinue
                    $errorWritten = $true
                }
                catch {
                    # Write-ProfileError failed, will fall through to Write-Error
                }
            }
            
            if (-not $errorWritten) {
                # Use Write-Error but suppress any exceptions it might throw
                try {
                    # Temporarily set ErrorActionPreference to Continue to prevent Write-Error from throwing
                    $oldErrorAction = $ErrorActionPreference
                    $ErrorActionPreference = 'Continue'
                    Write-Error -Message $errorMessage -ErrorAction Continue
                    $ErrorActionPreference = $oldErrorAction
                }
                catch {
                    # Silently ignore - error was written
                }
            }
        }
    }
    catch {
        # Silently ignore any exceptions - tests expect this function to not throw
        # The error has already been written, so we don't need to do anything else
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
        [ValidateNotNullOrEmpty()]
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
        try {
            $innerMessage = $ErrorRecord.Exception.InnerException.Message
            $innerType = $ErrorRecord.Exception.InnerException.GetType().Name
            if ($null -ne $innerMessage) {
                $null = $errorInfo | Add-Member -MemberType NoteProperty -Name 'InnerException' -Value $innerMessage -PassThru -Force
            }
            if ($null -ne $innerType) {
                $null = $errorInfo | Add-Member -MemberType NoteProperty -Name 'InnerExceptionType' -Value $innerType -PassThru -Force
            }
        }
        catch {
            # Silently ignore if Add-Member fails
        }
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


