# ===============================================
# Error handling diagnostic functions
# Enhanced error logging, recovery, and fragment loading
# ===============================================

<#
Enhanced error handling and recovery mechanisms for the PowerShell profile.

Features:
- Global error handler with smart fallbacks
- Error logging to file for debugging
- Recovery mechanisms for common failures
- Enhanced error reporting with context
- Command failure tracking and suggestions
#>

try {
    if ($null -ne (Get-Variable -Name 'ErrorHandlingLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Enhanced error logging function
    <#
    .SYNOPSIS
        Logs errors with enhanced context and formatting.
    .DESCRIPTION
        Provides comprehensive error logging with timestamps, context, and suggestions.
        Logs to both console (when debugging) and file for persistent debugging.
    .PARAMETER ErrorRecord
        The error record to log.
    .PARAMETER Context
        Additional context about where the error occurred.
    .PARAMETER Category
        Error category for better organization.
    #>
    function Write-ProfileError {
        param(
            [Parameter(Mandatory)] [System.Management.Automation.ErrorRecord]$ErrorRecord,
            [string]$Context = "",
            [ValidateSet('Profile', 'Fragment', 'Command', 'Network', 'System')] [string]$Category = 'Profile'
        )

        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 3) {
                Write-Host "  [diagnostics.error-handling] Writing profile error - Category: $Category, Context: $Context" -ForegroundColor DarkGray
            }
        }

        # Use DateTimeFormatting module if available for unified date formatting
        $timestamp = if (Get-Command Format-DateTimeLog -ErrorAction SilentlyContinue) {
            Format-DateTimeLog -DateTime (Get-Date)
        }
        elseif (Get-Command Format-DateTime -ErrorAction SilentlyContinue) {
            Format-DateTime -DateTime (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
        }
        elseif (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
            # Fallback to Format-LocaleDate if DateTimeFormatting not available
            Format-LocaleDate (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
        }
        else {
            # Final fallback to standard format
            (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        $errorMessage = $ErrorRecord.Exception.Message
        $errorType = $ErrorRecord.Exception.GetType().Name
        $scriptName = $ErrorRecord.InvocationInfo.ScriptName
        $lineNumber = $ErrorRecord.InvocationInfo.ScriptLineNumber

        # Format error message
        $formattedError = @"
[$timestamp] [$Category] Error in ${scriptName}:$lineNumber
Context: $Context
Type: $errorType
Message: $errorMessage
"@

        # Log to file if debug mode is enabled
        if ($env:PS_PROFILE_DEBUG) {
            # Use cross-platform home directory
            $userHome = if (Test-Path Function:\Get-UserHome) {
                Get-UserHome
            }
            elseif ($env:HOME) {
                $env:HOME
            }
            else {
                $env:USERPROFILE
            }

            if ($userHome) {
                $logDir = Join-Path $userHome '.local' 'share' 'powershell'
                if (-not ($logDir -and -not [string]::IsNullOrWhiteSpace($logDir) -and (Test-Path -LiteralPath $logDir))) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
                $logFile = Join-Path $logDir 'profile-errors.log'
            }
            else {
                $logFile = $null
            }

            if ($logFile) {
                try {
                    $formattedError | Out-File -FilePath $logFile -Append -Encoding UTF8
                    if ($debugLevel -ge 2) {
                        Write-Verbose "[diagnostics.error-handling] Error logged to file: $logFile"
                    }
                }
                catch {
                    # Level 1: Log error
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.error-handling.file-log' -Context @{
                                log_file                = $logFile
                                original_error_category = $Category
                            }
                        }
                        else {
                            Write-Error "Failed to write to error log: $($_.Exception.Message)"
                        }
                    }
                    if ($debugLevel -ge 2) {
                        Write-Verbose "[diagnostics.error-handling] Failed to write to error log: $($_.Exception.Message)"
                    }
                    if ($debugLevel -ge 3) {
                        Write-Host "  [diagnostics.error-handling] File logging error - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), LogFile: $logFile" -ForegroundColor DarkGray
                    }
                }
            }
        }

        # Console output based on debug level
        $suppressConsole = $false
        if ($Category -eq 'Fragment') {
            $fragmentSource = $ErrorRecord.InvocationInfo.ScriptName
            if (Get-Command -Name 'Test-FragmentWarningSuppressed' -ErrorAction SilentlyContinue) {
                try {
                    $suppressConsole = Test-FragmentWarningSuppressed -FragmentName $fragmentSource
                }
                catch {
                    $suppressConsole = $false
                }
            }
        }

        if (-not $suppressConsole) {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    Write-Host $formattedError -ForegroundColor Red
                }
                if ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.error-handling] Error displayed - Category: $Category, Type: $errorType"
                }
                if ($debugLevel -ge 3) {
                    Write-Host "  [diagnostics.error-handling] Error details - Script: $scriptName, Line: $lineNumber, Context: $Context" -ForegroundColor DarkGray
                }
            }
            else {
                Write-Warning "$Category Error: $errorMessage"
            }
        }
    }

    # Global error handler with recovery suggestions
    <#
    .SYNOPSIS
        Enhanced global error handler with recovery suggestions.
    .DESCRIPTION
        Provides intelligent error handling with suggestions for common issues.
        Attempts recovery where possible and provides helpful guidance.
    .PARAMETER ErrorRecord
        The error record to handle.
    #>
    function Invoke-ProfileErrorHandler {
        param([System.Management.Automation.ErrorRecord]$ErrorRecord)

        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 2) {
                Write-Verbose "[diagnostics.error-handling] Invoking profile error handler"
            }
        }

        $errorMessage = $ErrorRecord.Exception.Message
        $scriptName = $ErrorRecord.InvocationInfo.ScriptName

        # Log the error
        Write-ProfileError -ErrorRecord $ErrorRecord -Context "Global error handler"

        # Provide recovery suggestions for common errors
        switch -Regex ($errorMessage) {
            "CommandNotFoundException" {
                if ($errorMessage -match "The term '(.+)' is not recognized") {
                    $command = $matches[1]
                    Write-Host "Suggestion: Install missing command '$command' or check PATH" -ForegroundColor Yellow
                    # Try to suggest installation commands for common tools
                    if ($command -in @('scoop', 'choco', 'winget')) {
                        Write-Host "Try: Install $command from https://$command.sh/" -ForegroundColor Cyan
                    }
                }
            }
            "Network" {
                Write-Host "Suggestion: Check network connectivity and proxy settings" -ForegroundColor Yellow
            }
            "Access.*denied" {
                Write-Host "Suggestion: Run as administrator or check permissions" -ForegroundColor Yellow
            }
            "Module.*not.*found" {
                if ($errorMessage -match "Module '(.+)'") {
                    $module = $matches[1]
                    Write-Host "Suggestion: Install module with: Install-Module $module" -ForegroundColor Cyan
                }
            }
        }

        # Don't suppress the original error, just add context
        if ($debugLevel -ge 3) {
            Write-Host "  [diagnostics.error-handling] Re-throwing error after handling" -ForegroundColor DarkGray
        }
        throw $ErrorRecord
    }

    # Enhanced fragment loading with retry logic
    <#
    .SYNOPSIS
        Loads profile fragments with enhanced error handling and retry logic.
    .DESCRIPTION
        Wraps fragment loading with retry mechanisms and better error reporting.
        Attempts to recover from transient failures.
    .PARAMETER FragmentPath
        Path to the fragment file to load.
    .PARAMETER FragmentName
        Name of the fragment for logging.
    .PARAMETER MaxRetries
        Maximum number of retry attempts.
    #>
    function Invoke-SafeFragmentLoad {
        param(
            [Parameter(Mandatory)] [string]$FragmentPath,
            [Parameter(Mandatory)] [string]$FragmentName,
            [int]$MaxRetries = 2
        )

        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                Write-Verbose "[diagnostics.error-handling] Loading fragment safely: $FragmentName"
            }
        }

        $attempt = 0
        $lastError = $null
        $loadStartTime = [DateTime]::Now

        do {
            $attempt++
            $attemptStartTime = [DateTime]::Now
            try {
                $null = . $FragmentPath
                $loadDuration = ([DateTime]::Now - $loadStartTime).TotalMilliseconds
                $attemptDuration = ([DateTime]::Now - $attemptStartTime).TotalMilliseconds
                
                if ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.error-handling] Fragment '$FragmentName' loaded successfully in ${loadDuration}ms (attempt $attempt took ${attemptDuration}ms)"
                }
                if ($debugLevel -ge 3) {
                    Write-Host "  [diagnostics.error-handling] Fragment load success - Fragment: $FragmentName, Attempt: $attempt, Duration: ${loadDuration}ms" -ForegroundColor DarkGray
                }
                return $true
            }
            catch {
                $lastError = $_
                $attemptDuration = ([DateTime]::Now - $attemptStartTime).TotalMilliseconds
                Write-ProfileError -ErrorRecord $_ -Context "Fragment load attempt $attempt/$($MaxRetries + 1)" -Category 'Fragment'

                # Level 1: Log error
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.error-handling.fragment-load' -Context @{
                            fragment_name       = $FragmentName
                            fragment_path       = $FragmentPath
                            attempt             = $attempt
                            max_retries         = $MaxRetries
                            attempt_duration_ms = $attemptDuration
                        }
                    }
                }
                
                if ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.error-handling] Fragment load attempt $attempt failed in ${attemptDuration}ms: $($_.Exception.Message)"
                }
                
                if ($debugLevel -ge 3) {
                    Write-Host "  [diagnostics.error-handling] Fragment load attempt error - Fragment: $FragmentName, Attempt: $attempt, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                }

                if ($attempt -le $MaxRetries) {
                    # Exponential backoff
                    $delay = [math]::Pow(2, $attempt - 1) * 1000
                    Write-Host "Retrying fragment load in $($delay)ms..." -ForegroundColor Yellow
                    if ($debugLevel -ge 2) {
                        Write-Verbose "[diagnostics.error-handling] Waiting ${delay}ms before retry (exponential backoff)"
                    }
                    Start-Sleep -Milliseconds $delay
                }
            }
        } while ($attempt -le $MaxRetries)

        # Final failure
        $totalDuration = ([DateTime]::Now - $loadStartTime).TotalMilliseconds
        if ($debugLevel -ge 1) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to load profile fragment after all retries" -OperationName 'diagnostics.error-handling.fragment-load' -Context @{
                    fragment_name     = $FragmentName
                    fragment_path     = $FragmentPath
                    total_attempts    = $attempt
                    total_duration_ms = $totalDuration
                    final_error       = $lastError.Exception.Message
                } -Code 'FRAGMENT_LOAD_FAILED'
            }
            else {
                Write-Warning "Failed to load profile fragment '$FragmentName' after $($MaxRetries + 1) attempts: $($lastError.Exception.Message)"
            }
        }
        if ($debugLevel -ge 2) {
            Write-Verbose "[diagnostics.error-handling] Fragment load failed after $attempt attempts in ${totalDuration}ms"
        }
        return $false
    }

    # Command failure tracker
    if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileCommandFailures) {
        $global:PSProfileCommandFailures = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::new()
    }

    # Override the default error action preference temporarily for better error handling
    # Store original preference
    if (-not $global:OriginalErrorActionPreference) {
        $global:OriginalErrorActionPreference = $ErrorActionPreference
    }

    # Set up enhanced error handling for interactive sessions
    if ($Host.Name -notmatch 'Server|Console|Default') {
        # Add global error handler
        $global:ErrorActionPreference = 'Continue'  # Don't stop on errors, handle them gracefully

        # Set up trap for unhandled errors
        trap {
            Invoke-ProfileErrorHandler -ErrorRecord $_
            continue
        }
    }

    Set-Variable -Name 'ErrorHandlingLoaded' -Value $true -Scope Global -Force
}
catch {
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        if ($debugLevel -ge 1) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'error-handling' -Context @{
                    fragment = 'diagnostics-error-handling'
                }
            }
            else {
                Write-Error "Error handling fragment failed: $($_.Exception.Message)"
            }
        }
        if ($debugLevel -ge 2) {
            Write-Verbose "[error-handling] Fragment load error: $($_.Exception.Message)"
        }
        if ($debugLevel -ge 3) {
            Write-Host "  [error-handling] Error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
    else {
        # Always log errors even if debug is off
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'error-handling' -Context @{
                fragment = 'diagnostics-error-handling'
            }
        }
        else {
            Write-Warning "Error handling fragment failed: $($_.Exception.Message)"
        }
    }
}

