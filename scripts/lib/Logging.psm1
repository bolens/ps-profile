<#
scripts/lib/Logging.psm1

.SYNOPSIS
    Logging and output formatting utilities.

.DESCRIPTION
    Provides consistent message formatting and logging functionality for utility scripts,
    including structured logging, log file rotation, and multiple log levels.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

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
        [string]$Message,

        [System.ConsoleColor]$ForegroundColor,

        [switch]$IsWarning,

        [switch]$IsError,

        [ValidateSet('Debug', 'Info', 'Warning', 'Error')]
        [string]$LogLevel,

        [switch]$StructuredOutput,

        [string]$LogFile,

        [switch]$AppendLog,

        [int]$MaxLogFileSizeMB = 10,

        [int]$MaxLogFiles = 5
    )

    # Determine log level
    $level = if ($LogLevel) {
        $LogLevel
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
        if ($StructuredOutput) {
            $logEntry = @{
                Timestamp = [DateTime]::UtcNow.ToString('o')
                Level     = $level
                Message   = $Message
            } | ConvertTo-Json -Compress
        }
        else {
            $logEntry = "[$([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss'))] [$level] $Message"
        }
    }

    # Write to log file if specified
    if ($LogFile -and $logEntry) {
        try {
            $logDir = Split-Path -Path $LogFile -Parent
            if ($logDir -and -not (Test-Path -Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }
            
            # Rotate log file if needed
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
            
            if ($AppendLog -or (Test-Path -Path $LogFile)) {
                Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
            }
            else {
                Set-Content -Path $LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
            }
        }
        catch {
            Write-Warning "Failed to write to log file '$LogFile': $($_.Exception.Message)"
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
            Write-Error $Message
        }
        'Warning' {
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

