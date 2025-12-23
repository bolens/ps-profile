<#
scripts/lib/core/Retry.psm1

.SYNOPSIS
    Retry logic utilities with exponential backoff support.

.DESCRIPTION
    Provides functions for executing operations with retry logic, exponential backoff,
    and configurable retry conditions. Centralizes retry patterns used across
    multiple modules and scripts.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import Logging module if available for consistent output
$loggingModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Executes a scriptblock with retry logic and exponential backoff.

.DESCRIPTION
    Executes a scriptblock with configurable retry attempts, delays, and backoff
    strategies. Supports exponential backoff, linear delays, and custom retry conditions.

.PARAMETER ScriptBlock
    The scriptblock to execute.

.PARAMETER MaxRetries
    Maximum number of retry attempts. Defaults to 3.

.PARAMETER RetryDelaySeconds
    Base delay between retries in seconds. Defaults to 1.

.PARAMETER ExponentialBackoff
    If specified, uses exponential backoff (delay doubles with each retry).

.PARAMETER LinearBackoff
    If specified, uses linear backoff (delay increases linearly).

.PARAMETER MaxDelaySeconds
    Maximum delay between retries in seconds. Defaults to 60.

.PARAMETER RetryCondition
    Optional scriptblock that determines if an error is retryable. If not provided,
    all errors are considered retryable.

.PARAMETER OnRetry
    Optional scriptblock to execute before each retry attempt.

.OUTPUTS
    The result of the scriptblock execution.

.EXAMPLE
    $result = Invoke-WithRetry -ScriptBlock { Get-Content $file } -MaxRetries 3

.EXAMPLE
    $result = Invoke-WithRetry -ScriptBlock { Invoke-WebRequest $url } -ExponentialBackoff -RetryDelaySeconds 2

.EXAMPLE
    $result = Invoke-WithRetry -ScriptBlock { Import-Module $module } -RetryCondition { $_.Exception.Message -match 'timeout|network' }
#>
function Invoke-WithRetry {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [ValidateRange(0, 10)]
        [int]$MaxRetries = 3,

        [ValidateRange(0, 60)]
        [double]$RetryDelaySeconds = 1,

        [switch]$ExponentialBackoff,

        [switch]$LinearBackoff,

        [ValidateRange(1, 300)]
        [int]$MaxDelaySeconds = 60,

        [scriptblock]$RetryCondition,

        [scriptblock]$OnRetry
    )

    $attempt = 0
    $lastException = $null

    do {
        try {
            $attempt++
            $result = & $ScriptBlock
            return $result
        }
        catch {
            $lastException = $_

            # Check if error is retryable
            $isRetryable = $true
            if ($RetryCondition) {
                $isRetryable = & $RetryCondition $_
            }

            if (-not $isRetryable -or $attempt -gt $MaxRetries) {
                throw
            }

            # Calculate delay
            $delay = Get-RetryDelay -Attempt $attempt -BaseDelaySeconds $RetryDelaySeconds -ExponentialBackoff:$ExponentialBackoff -LinearBackoff:$LinearBackoff -MaxDelaySeconds $MaxDelaySeconds

            # Execute OnRetry callback if provided
            if ($OnRetry) {
                try {
                    & $OnRetry -Attempt $attempt -MaxRetries $MaxRetries -DelaySeconds $delay -Exception $_
                }
                catch {
                    # Ignore errors in OnRetry callback
                }
            }

            # Log retry attempt if Logging module is available
            if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                Write-ScriptMessage -Message "Operation failed, retrying in $delay seconds... (attempt $attempt of $($MaxRetries + 1))" -LogLevel 'Warning'
            }
            elseif ($VerbosePreference -eq 'Continue') {
                Write-Verbose "Operation failed, retrying in $delay seconds... (attempt $attempt of $($MaxRetries + 1))"
            }

            Start-Sleep -Seconds $delay
        }
    } while ($attempt -le $MaxRetries)

    # Should not reach here, but throw last exception if we do
    if ($lastException) {
        throw $lastException
    }
}

<#
.SYNOPSIS
    Tests if an error is retryable based on common patterns.

.DESCRIPTION
    Determines if an error should be retried based on common error patterns
    like timeout, network, connection, etc.

.PARAMETER Exception
    The exception to test.

.PARAMETER RetryablePatterns
    Array of string patterns that indicate retryable errors. Defaults to common
    network/timeout patterns.

.OUTPUTS
    System.Boolean. Returns $true if the error is retryable, $false otherwise.

.EXAMPLE
    if (Test-IsRetryableError -Exception $_.Exception) {
        # Retry the operation
    }

.EXAMPLE
    $isRetryable = Test-IsRetryableError -Exception $error -RetryablePatterns @('timeout', 'connection')
#>
function Test-IsRetryableError {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [Exception]$Exception,

        [string[]]$RetryablePatterns = @('timeout', 'connection', 'network', 'unreachable', 'name resolution', 'dns', 'temporary', 'retry', 'busy', 'locked')
    )

    $errorMessage = $Exception.Message
    if ([string]::IsNullOrWhiteSpace($errorMessage)) {
        return $false
    }

    $errorMessageLower = $errorMessage.ToLowerInvariant()

    foreach ($pattern in $RetryablePatterns) {
        if ($errorMessageLower -match $pattern) {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
    Calculates retry delay based on attempt number and backoff strategy.

.DESCRIPTION
    Calculates the delay between retry attempts based on the attempt number,
    base delay, and backoff strategy (exponential, linear, or fixed).

.PARAMETER Attempt
    The current attempt number (1-based).

.PARAMETER BaseDelaySeconds
    The base delay in seconds.

.PARAMETER ExponentialBackoff
    If specified, uses exponential backoff (delay = baseDelay * 2^(attempt-1)).

.PARAMETER LinearBackoff
    If specified, uses linear backoff (delay = baseDelay * attempt).

.PARAMETER MaxDelaySeconds
    Maximum delay in seconds. Defaults to 60.

.OUTPUTS
    System.Double. The delay in seconds.

.EXAMPLE
    $delay = Get-RetryDelay -Attempt 2 -BaseDelaySeconds 1 -ExponentialBackoff
    # Returns 2 (1 * 2^1)

.EXAMPLE
    $delay = Get-RetryDelay -Attempt 3 -BaseDelaySeconds 2 -LinearBackoff
    # Returns 6 (2 * 3)
#>
function Get-RetryDelay {
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [int]$Attempt,

        [Parameter(Mandatory)]
        [double]$BaseDelaySeconds,

        [switch]$ExponentialBackoff,

        [switch]$LinearBackoff,

        [ValidateRange(1, 300)]
        [int]$MaxDelaySeconds = 60
    )

    $delay = if ($ExponentialBackoff) {
        $BaseDelaySeconds * [Math]::Pow(2, $Attempt - 1)
    }
    elseif ($LinearBackoff) {
        $BaseDelaySeconds * $Attempt
    }
    else {
        $BaseDelaySeconds
    }

    # Cap at maximum delay
    if ($delay -gt $MaxDelaySeconds) {
        $delay = $MaxDelaySeconds
    }

    return $delay
}

Export-ModuleMember -Function @(
    'Invoke-WithRetry',
    'Test-IsRetryableError',
    'Get-RetryDelay'
)

