<#
scripts/lib/ExitCodes.psm1

.SYNOPSIS
    Exit code constants and exit handling functions.

.DESCRIPTION
    Provides standardized exit code constants and exit handling functions
    for consistent error handling across utility scripts.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Standardized exit code constants
# These match the conventions documented in CONTRIBUTING.md and ensure consistent
# error reporting across all utility scripts in the repository.
$script:EXIT_SUCCESS = 0              # Operation completed successfully
$script:EXIT_VALIDATION_FAILURE = 1    # Validation/check failure (expected, non-fatal)
$script:EXIT_SETUP_ERROR = 2           # Setup/configuration error (unexpected, fatal)
$script:EXIT_OTHER_ERROR = 3          # Other runtime errors (unexpected, fatal)

<#
.SYNOPSIS
    Exits the script with a standardized exit code.

.DESCRIPTION
    Exits the script with a standardized exit code and optional message.
    This ensures consistent exit code usage across all utility scripts.

.PARAMETER ExitCode
    The exit code to use. Use constants: EXIT_SUCCESS, EXIT_VALIDATION_FAILURE, EXIT_SETUP_ERROR.

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

    if ($Message) {
        Write-Output $Message
    }

    if ($ErrorRecord) {
        Write-Error $ErrorRecord
    }

    exit $ExitCode
}

# Export functions and variables
Export-ModuleMember -Function 'Exit-WithCode'
Export-ModuleMember -Variable @(
    'EXIT_SUCCESS',
    'EXIT_VALIDATION_FAILURE',
    'EXIT_SETUP_ERROR',
    'EXIT_OTHER_ERROR'
)

