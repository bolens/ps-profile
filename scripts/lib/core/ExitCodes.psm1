<#
scripts/lib/ExitCodes.psm1

.SYNOPSIS
    Exit code constants and exit handling functions.

.DESCRIPTION
    Provides standardized exit code constants and exit handling functions
    for consistent error handling across utility scripts.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses an enum for type-safe exit codes.
    The $EXIT_ constants are deprecated - use [ExitCode]::Value directly.
#>

# Exit code enum for type-safe exit code handling
enum ExitCode {
    Success = 0              # Operation completed successfully
    ValidationFailure = 1    # Validation/check failure (expected, non-fatal)
    SetupError = 2           # Setup/configuration error (unexpected, fatal)
    OtherError = 3           # Other runtime errors (unexpected, fatal)
    TestFailure = 4          # Tests failed (at least one test failed)
    TestTimeout = 5          # Tests timed out
    CoverageFailure = 6      # Code coverage below threshold
    NoTestsFound = 7         # No tests found to run
    WatchModeCanceled = 8    # Watch mode canceled by user
}

# Standardized exit code constants (deprecated - use ExitCode enum directly)
# These are kept for legacy code that hasn't been migrated yet
# New code should use [ExitCode]::Value directly instead of $EXIT_ constants
# These match the conventions documented in CONTRIBUTING.md and ensure consistent
# error reporting across all utility scripts in the repository.
$script:EXIT_SUCCESS = [int][ExitCode]::Success              # Operation completed successfully
$script:EXIT_VALIDATION_FAILURE = [int][ExitCode]::ValidationFailure    # Validation/check failure (expected, non-fatal)
$script:EXIT_SETUP_ERROR = [int][ExitCode]::SetupError           # Setup/configuration error (unexpected, fatal)
$script:EXIT_OTHER_ERROR = [int][ExitCode]::OtherError          # Other runtime errors (unexpected, fatal)

# Additional granular exit codes for test runner
$script:EXIT_TEST_FAILURE = [int][ExitCode]::TestFailure         # Tests failed (at least one test failed)
$script:EXIT_TEST_TIMEOUT = [int][ExitCode]::TestTimeout          # Tests timed out
$script:EXIT_COVERAGE_FAILURE = [int][ExitCode]::CoverageFailure      # Code coverage below threshold
$script:EXIT_NO_TESTS_FOUND = [int][ExitCode]::NoTestsFound        # No tests found to run
$script:EXIT_WATCH_MODE_CANCELED = [int][ExitCode]::WatchModeCanceled  # Watch mode canceled by user

<#
.SYNOPSIS
    Exits the script with a standardized exit code.

.DESCRIPTION
    Exits the script with a standardized exit code and optional message.
    This ensures consistent exit code usage across all utility scripts.
    
    Requires an ExitCode enum value for type safety.

.PARAMETER ExitCode
    The exit code to use. Must be an ExitCode enum value.
    Use enum values: [ExitCode]::Success, [ExitCode]::ValidationFailure, etc.

.PARAMETER Message
    Optional message to display before exiting.

.PARAMETER ErrorRecord
    Optional error record to display before exiting.

.EXAMPLE
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Validation failed"

.EXAMPLE
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
#>
function Exit-WithCode {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ExitCode]$ExitCode,

        [string]$Message,

        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    # Convert enum to integer
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
