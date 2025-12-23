<#
scripts/utils/code-quality/modules/TestRetry.psm1

.SYNOPSIS
    Test retry logic utilities for the PowerShell profile test runner.

.DESCRIPTION
    Provides functions for executing tests with retry logic to handle flaky tests
    and transient failures.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Executes tests with retry logic for handling flaky tests.

.DESCRIPTION
    Runs the specified test script block with configurable retry logic,
    including exponential backoff and maximum retry attempts.

.PARAMETER ScriptBlock
    The script block containing the test execution logic.

.PARAMETER MaxRetries
    Maximum number of retry attempts (default: 3).

.PARAMETER RetryDelaySeconds
    Base delay between retries in seconds (default: 1).

.PARAMETER ExponentialBackoff
    Enable exponential backoff for retry delays (default: true).

.PARAMETER RetryOnFailure
    Only retry on test failures, not on setup errors (default: true).

.PARAMETER SuppressRetryWarnings
    Suppress retry warning messages by changing log level to Debug (default: false).

.OUTPUTS
    Test execution result object
#>
function Invoke-TestWithRetry {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [ValidateRange(0, 10)]
        [int]$MaxRetries = 3,

        [ValidateRange(0, 60)]
        [int]$RetryDelaySeconds = 1,

        [switch]$ExponentialBackoff,

        [switch]$RetryOnFailure,

        [switch]$SuppressRetryWarnings
    )

    $attempt = 0
    $lastException = $null

    do {
        try {
            $attempt++
            if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                Write-ScriptMessage -Message "Test execution attempt $attempt of $($MaxRetries + 1)" -LogLevel 'Info'
            }

            $result = & $ScriptBlock

            # Check if the result indicates failure
            if ($result -and $result.FailedCount -gt 0) {
                if ($RetryOnFailure -and $attempt -le $MaxRetries) {
                    $lastException = [Exception]::new("Test execution failed with $($result.FailedCount) failures")
                    throw $lastException
                }
            }

            return $result
        }
        catch {
            $lastException = $_

            if ($attempt -le $MaxRetries) {
                $delay = if ($ExponentialBackoff) {
                    $RetryDelaySeconds * [Math]::Pow(2, $attempt - 1)
                }
                else {
                    $RetryDelaySeconds
                }

                if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                    $logLevel = if ($SuppressRetryWarnings) { 'Debug' } else { 'Warning' }
                    Write-ScriptMessage -Message "Test execution failed, retrying in $delay seconds... ($($MaxRetries - $attempt + 1) attempts remaining)" -LogLevel $logLevel
                }
                Start-Sleep -Seconds $delay
            }
        }
    } while ($attempt -le $MaxRetries)

    # If we get here, all retries failed
    if ($lastException) {
        throw $lastException
    }
}

Export-ModuleMember -Function @(
    'Invoke-TestWithRetry'
)

