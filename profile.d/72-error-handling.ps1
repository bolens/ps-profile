<#
# 72-error-handling.ps1

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

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
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
                if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
                $logFile = Join-Path $logDir 'profile-errors.log'
            }
            else {
                $logFile = $null
            }

            if ($logFile) {
                try {
                    $formattedError | Out-File -FilePath $logFile -Append -Encoding UTF8
                }
                catch {
                    # Fallback to console if file logging fails
                    Write-Verbose "Failed to write to error log: $($_.Exception.Message)"
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
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host $formattedError -ForegroundColor Red
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

        $attempt = 0
        $lastError = $null

        do {
            $attempt++
            try {
                $null = . $FragmentPath
                return $true
            }
            catch {
                $lastError = $_
                Write-ProfileError -ErrorRecord $_ -Context "Fragment load attempt $attempt/$($MaxRetries + 1)" -Category 'Fragment'

                if ($attempt -le $MaxRetries) {
                    # Exponential backoff
                    $delay = [math]::Pow(2, $attempt - 1) * 1000
                    Write-Host "Retrying fragment load in $($delay)ms..." -ForegroundColor Yellow
                    Start-Sleep -Milliseconds $delay
                }
            }
        } while ($attempt -le $MaxRetries)

        # Final failure
        Write-Warning "Failed to load profile fragment '$FragmentName' after $($MaxRetries + 1) attempts: $($lastError.Exception.Message)"
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
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Error handling fragment failed: $($_.Exception.Message)" }
}
