<#
scripts/lib/Logging.psm1

.SYNOPSIS
    Logging and output formatting utilities.

.DESCRIPTION
    Provides consistent message formatting and logging functionality for utility scripts,
    including structured logging, log file rotation, and multiple log levels.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe log level handling.
    
    This module uses strict mode for enhanced error checking.
#>

# Enable strict mode for enhanced error checking
Set-StrictMode -Version Latest

# Import CommonEnums for LogLevel enum
$commonEnumsPath = Join-Path $PSScriptRoot 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Locale module for locale-aware date formatting
# Use SafeImport module if available, otherwise fall back to manual check
$safeImportModulePath = Join-Path $PSScriptRoot 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

$localeModulePath = Join-Path $PSScriptRoot 'Locale.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $localeModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($localeModulePath -and -not [string]::IsNullOrWhiteSpace($localeModulePath) -and (Test-Path -LiteralPath $localeModulePath)) {
        Import-Module $localeModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Writes a formatted message to the output stream.

.DESCRIPTION
    Provides consistent message formatting for utility scripts.
    Uses Write-Output for pipeline compatibility.
    Supports structured logging with log levels.

.PARAMETER Message
    The message to write.

.PARAMETER ForegroundColor
    Optional foreground color for the message (for Write-Host compatibility).

.PARAMETER IsWarning
    If specified, writes the message as a warning using Write-Warning.

.PARAMETER IsError
    If specified, writes the message as an error using Write-Error.

.PARAMETER LogLevel
    Optional log level: Debug, Info, Warning, Error. Overrides IsWarning/IsError if specified.

.PARAMETER StructuredOutput
    If specified, outputs structured JSON format for logging systems.

.PARAMETER LogFile
    Optional path to a log file. If specified, messages are appended to the file.

.PARAMETER AppendLog
    If specified with LogFile, appends to existing log file. Otherwise overwrites.

.PARAMETER MaxLogFileSizeMB
    Maximum log file size in MB before rotation. Defaults to 10MB. Set to 0 to disable rotation.

.PARAMETER MaxLogFiles
    Maximum number of rotated log files to keep. Defaults to 5.

.EXAMPLE
    Write-ScriptMessage -Message "Running analysis..."

.EXAMPLE
    Write-ScriptMessage -Message "Warning: deprecated feature" -IsWarning

.EXAMPLE
    Write-ScriptMessage -Message "Error: validation failed" -IsError

.EXAMPLE
    Write-ScriptMessage -Message "Debug info" -LogLevel Debug

.EXAMPLE
    Write-ScriptMessage -Message "Info message" -LogLevel Info -StructuredOutput

.EXAMPLE
    Write-ScriptMessage -Message "Log entry" -LogFile "script.log" -AppendLog

.EXAMPLE
    Write-ScriptMessage -Message "Log entry" -LogFile "script.log" -AppendLog -MaxLogFileSizeMB 5 -MaxLogFiles 3
#>
function Write-ScriptMessage {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [System.ConsoleColor]$ForegroundColor,

        [switch]$IsWarning,

        [switch]$IsError,

        [LogLevel]$LogLevel,

        [switch]$StructuredOutput,

        [string]$LogFile,

        [switch]$AppendLog,

        [int]$MaxLogFileSizeMB = 10,

        [int]$MaxLogFiles = 5
    )

    # Determine log level
    $level = if ($LogLevel) {
        $LogLevel.ToString()
    }
    elseif ($IsError) {
        'Error'
    }
    elseif ($IsWarning) {
        'Warning'
    }
    else {
        'Info'
    }

    # Prepare log entry for file output
    $logEntry = $null
    if ($LogFile -or $StructuredOutput) {
        $now = [DateTime]::UtcNow
        
        if ($StructuredOutput) {
            # ISO 8601 format for structured output (always UTC, invariant culture)
            $logEntry = @{
                Timestamp = $now.ToString('o')
                Level     = $level
                Message   = $Message
            } | ConvertTo-Json -Compress
        }
        else {
            # Use DateTimeFormatting module if available, otherwise fall back to manual formatting
            if (Get-Command Format-DateTimeLog -ErrorAction SilentlyContinue) {
                $timestamp = Format-DateTimeLog -DateTime $now -UseUTC
            }
            elseif (Get-Command Format-DateWithFallback -ErrorAction SilentlyContinue) {
                $timestamp = Format-DateWithFallback -Date $now -Format 'yyyy-MM-dd HH:mm:ss'
            }
            elseif (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
                $timestamp = Format-LocaleDate $now -Format 'yyyy-MM-dd HH:mm:ss'
            }
            else {
                # Fallback to invariant culture if Locale module not available
                $timestamp = $now.ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
            }
            $logEntry = "[$timestamp] [$level] $Message"
        }
    }

    # Write to log file if specified
    if ($LogFile -and $logEntry) {
        try {
            $logDir = Split-Path -Path $LogFile -Parent
            if ($logDir -and -not (Test-Path -Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }
            
            # Append if AppendLog is specified, otherwise overwrite
            if ($AppendLog) {
                # Append to existing file
                # Note: Rotation check happens before append to avoid rotating file we're about to append to
                # Rotate log file if needed (only if appending and file exists and is large enough)
                if ($MaxLogFileSizeMB -gt 0 -and (Test-Path -Path $LogFile)) {
                    $fileInfo = Get-Item -Path $LogFile -ErrorAction SilentlyContinue
                    if ($fileInfo -and ($fileInfo.Length / 1MB) -ge $MaxLogFileSizeMB) {
                        # Rotate existing log files
                        for ($i = $MaxLogFiles - 1; $i -ge 1; $i--) {
                            $oldFile = "$LogFile.$i"
                            $newFile = "$LogFile.$($i + 1)"
                            if (Test-Path -Path $oldFile) {
                                Move-Item -Path $oldFile -Destination $newFile -Force -ErrorAction SilentlyContinue
                            }
                        }
                        # Move current log to .1
                        Move-Item -Path $LogFile -Destination "$LogFile.1" -Force -ErrorAction SilentlyContinue
                    }
                }
                # Append to existing file (or create new if rotated or doesn't exist)
                Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
            }
            else {
                # Overwrite file (creates new file or replaces existing)
                # Rotate log file if needed (only if overwriting and file exists and is large enough)
                if ($MaxLogFileSizeMB -gt 0 -and (Test-Path -Path $LogFile)) {
                    $fileInfo = Get-Item -Path $LogFile -ErrorAction SilentlyContinue
                    if ($fileInfo -and ($fileInfo.Length / 1MB) -ge $MaxLogFileSizeMB) {
                        # Rotate existing log files
                        for ($i = $MaxLogFiles - 1; $i -ge 1; $i--) {
                            $oldFile = "$LogFile.$i"
                            $newFile = "$LogFile.$($i + 1)"
                            if (Test-Path -Path $oldFile) {
                                Move-Item -Path $oldFile -Destination $newFile -Force -ErrorAction SilentlyContinue
                            }
                        }
                        # Move current log to .1
                        Move-Item -Path $LogFile -Destination "$LogFile.1" -Force -ErrorAction SilentlyContinue
                    }
                }
                # Overwrite file (creates new file or replaces existing)
                Set-Content -Path $LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
            }
        }
        catch {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to write to log file" -OperationName 'logging.write-log-file' -Context @{
                            # Technical context
                            log_file             = $LogFile
                            log_dir              = if ($LogFile) { Split-Path -Parent $LogFile } else { $null }
                            append_log           = $AppendLog
                            max_log_file_size_mb = $MaxLogFileSizeMB
                            max_log_files        = $MaxLogFiles
                            # Error context
                            error_message        = $_.Exception.Message
                            error_type           = $_.Exception.GetType().FullName
                            # Operation context
                            log_level            = $level
                            message_length       = if ($Message) { $Message.Length } else { 0 }
                        } -Code 'LogFileWriteFailed'
                    }
                    else {
                        Write-Warning "[logging.write-log-file] Failed to write to log file '$LogFile': $($_.Exception.Message)"
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [logging.write-log-file] Log file write error details - LogFile: $LogFile, AppendLog: $AppendLog, MaxSizeMB: $MaxLogFileSizeMB, MaxFiles: $MaxLogFiles, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to write to log file" -OperationName 'logging.write-log-file' -Context @{
                        log_file             = $LogFile
                        log_dir              = if ($LogFile) { Split-Path -Parent $LogFile } else { $null }
                        append_log           = $AppendLog
                        max_log_file_size_mb = $MaxLogFileSizeMB
                        max_log_files        = $MaxLogFiles
                        error_message        = $_.Exception.Message
                        error_type           = $_.Exception.GetType().FullName
                        log_level            = $level
                        message_length       = if ($Message) { $Message.Length } else { 0 }
                    } -Code 'LogFileWriteFailed'
                }
                else {
                    Write-Warning "[logging.write-log-file] Failed to write to log file '$LogFile': $($_.Exception.Message)"
                }
            }
        }
    }

    # Structured output (JSON format) - also write to console
    if ($StructuredOutput) {
        Write-Output $logEntry
        return
    }

    # Standard output based on level
    switch ($level) {
        'Error' {
            # For error level, try to use structured error logging if available
            # Note: Write-ScriptMessage doesn't receive ErrorRecord, so we can't use Write-StructuredError here
            # This is intentional - Write-ScriptMessage is a formatting function, not an error handler
            Write-Error $Message -ErrorAction Continue
        }
        'Warning' {
            # For warning level, use standard Write-Warning
            # Note: Write-ScriptMessage is a formatting function, not a warning handler
            # Structured warnings should be handled at the call site
            Write-Warning $Message
        }
        'Debug' {
            Write-Debug $Message
        }
        'Info' {
            if ($ForegroundColor) {
                Write-Host $Message -ForegroundColor $ForegroundColor
            }
            else {
                Write-Output $Message
            }
        }
    }
}

# Export functions
Export-ModuleMember -Function 'Write-ScriptMessage'

