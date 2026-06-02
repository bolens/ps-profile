<#
scripts/lib/ExitCodes.psm1

.SYNOPSIS
    Exit code constants and exit handling functions.

.DESCRIPTION
    Provides standardized exit code constants and exit handling functions
    for consistent error handling across utility scripts.

    The ExitCode enum is defined in CommonEnums.psm1 via Add-Type, making it
    globally accessible. The $EXIT_* integer constants are exported for use at
    call sites — use $EXIT_* variables rather than ([ExitCode]::Value) expressions
    to avoid the PowerShell -File argument-parsing quirk where [Type]::Member
    without parentheses is stringified instead of evaluated.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+
    Load Order: import CommonEnums before this module.
#>

# Import CommonEnums so ExitCode (and LogLevel) are available as global .NET types
$commonEnumsPath = Join-Path $PSScriptRoot 'CommonEnums.psm1'
if (Test-Path -LiteralPath $commonEnumsPath) {
    Import-Module $commonEnumsPath -DisableNameChecking -Global -ErrorAction Stop
}

# Standardized exit code constants — exported for use at call sites.
# Prefer these over [ExitCode]:: expressions in script files.
$script:EXIT_SUCCESS             = [int][ExitCode]::Success
$script:EXIT_VALIDATION_FAILURE  = [int][ExitCode]::ValidationFailure
$script:EXIT_SETUP_ERROR         = [int][ExitCode]::SetupError
$script:EXIT_OTHER_ERROR         = [int][ExitCode]::OtherError
$script:EXIT_RUNTIME_ERROR       = [int][ExitCode]::OtherError   # alias
$script:EXIT_TEST_FAILURE        = [int][ExitCode]::TestFailure
$script:EXIT_TEST_TIMEOUT        = [int][ExitCode]::TestTimeout
$script:EXIT_COVERAGE_FAILURE    = [int][ExitCode]::CoverageFailure
$script:EXIT_NO_TESTS_FOUND      = [int][ExitCode]::NoTestsFound
$script:EXIT_WATCH_MODE_CANCELED = [int][ExitCode]::WatchModeCanceled


<#
.SYNOPSIS
    Exits the script with a standardized exit code.

.DESCRIPTION
    Exits the script with a standardized exit code and optional message.
    This ensures consistent exit code usage across all utility scripts.
    
    Requires an ExitCode enum value for type safety.

.PARAMETER ExitCode
    The exit code to use. Must be an ExitCode enum value.
    Use enum values: $EXIT_SUCCESS, $EXIT_VALIDATION_FAILURE, etc.

.PARAMETER Message
    Optional message to display before exiting.

.PARAMETER ErrorRecord
    Optional error record to display before exiting.

.EXAMPLE
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation failed"

.EXAMPLE
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
#>
function Exit-WithCode {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [int]$ExitCode,

        [string]$Message,

        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    # Convert enum to integer for process exit
    $exitCodeInt = [int]$ExitCode

    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        # Get enum name for better debug output
        $exitCodeName = $ExitCode.ToString()
        Write-Host "  [exit-codes.exit] Exiting with code: $exitCodeInt ($exitCodeName)" -ForegroundColor DarkGray
        if ($Message) {
            Write-Host "  [exit-codes.exit] Exit message: $Message" -ForegroundColor DarkGray
        }
        if ($ErrorRecord) {
            Write-Host "  [exit-codes.exit] Exit error: $($ErrorRecord.Exception.Message)" -ForegroundColor DarkGray
        }
    }
    
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        if ($ErrorRecord) {
            Write-Host "  [exit-codes.exit] Exit stack trace: $($ErrorRecord.ScriptStackTrace)" -ForegroundColor DarkGray
        }
    }

    if ($Message) {
        Write-Output $Message
    }

    if ($ErrorRecord) {
        Write-Error $ErrorRecord
    }

    if ($env:PS_PROFILE_TEST_MODE -eq '1') {
        if ($ErrorRecord) {
            throw $ErrorRecord
        }

        if ($exitCodeInt -ne 0) {
            $exitMessage = if ($Message) { $Message } else { "Exit requested with code $exitCodeInt" }
            throw [System.Management.Automation.RuntimeException]::new($exitMessage)
        }

        # Success exits are safe when invoked via `& script.ps1` and avoid false throws in callers.
        exit 0
    }

    exit $exitCodeInt
}

# Export functions, variables, and enum type
Export-ModuleMember -Function 'Exit-WithCode'
Export-ModuleMember -Variable @(
    'EXIT_SUCCESS',
    'EXIT_VALIDATION_FAILURE',
    'EXIT_SETUP_ERROR',
    'EXIT_OTHER_ERROR',
    'EXIT_TEST_FAILURE',
    'EXIT_TEST_TIMEOUT',
    'EXIT_COVERAGE_FAILURE',
    'EXIT_NO_TESTS_FOUND',
    'EXIT_WATCH_MODE_CANCELED'
)
# Note: Enums are automatically exported when the module is imported
