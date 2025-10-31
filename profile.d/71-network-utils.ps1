<#
# 71-network-utils.ps1

Network utilities with error recovery and timeout handling.
Provides resilient network operations for profile functions.
#>

# Skip if already loaded
if ($null -ne (Get-Variable -Name 'NetworkUtilsLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

# Network operation wrapper with retry and timeout
<#
.SYNOPSIS
    Executes a network operation with retry logic and timeout handling.
.DESCRIPTION
    Wraps network operations with automatic retry on transient failures
    and configurable timeouts to improve reliability.
.PARAMETER ScriptBlock
    The operation to execute.
.PARAMETER MaxRetries
    Maximum number of retry attempts. Default is 3.
.PARAMETER TimeoutSeconds
    Timeout in seconds for each attempt. Default is 30.
.PARAMETER RetryDelaySeconds
    Delay between retries in seconds. Default is 2.
#>
function Invoke-WithRetry {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$MaxRetries = 3,

        [int]$TimeoutSeconds = 30,

        [int]$RetryDelaySeconds = 2
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++

        try {
            # Create a job to run the operation with timeout
            $job = Start-Job -ScriptBlock $ScriptBlock -ErrorAction Stop

            # Wait for completion or timeout
            $completed = Wait-Job $job -Timeout $TimeoutSeconds

            if (-not $completed) {
                # Timeout occurred
                Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -ErrorAction SilentlyContinue
                throw "Operation timed out after $TimeoutSeconds seconds"
            }

            # Get the result
            $result = Receive-Job $job -ErrorAction Stop
            Remove-Job $job -ErrorAction SilentlyContinue

            return $result

        }
        catch {
            $lastError = $_

            # Check if this is a retryable error
            $retryableErrors = @(
                "timeout",
                "connection",
                "network",
                "unreachable",
                "name resolution",
                "dns"
            )

            $isRetryable = $false
            foreach ($pattern in $retryableErrors) {
                if ($_.Exception.Message -match $pattern) {
                    $isRetryable = $true
                    break
                }
            }

            if (-not $isRetryable -or $attempt -ge $MaxRetries) {
                # Not retryable or max retries reached
                throw
            }

            # Wait before retry
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Network operation failed (attempt $attempt/$MaxRetries): $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host "Retrying in $RetryDelaySeconds seconds..." -ForegroundColor Yellow
            }

            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    # Should not reach here, but just in case
    throw $lastError
}

# Enhanced network connectivity test with retry
<#
.SYNOPSIS
    Tests network connectivity with retry logic.
.DESCRIPTION
    Enhanced version of network connectivity testing with automatic retry
    for transient network issues.
.PARAMETER Target
    The target host or IP to test connectivity to.
.PARAMETER Port
    The port to test. Default is 80.
.PARAMETER TimeoutSeconds
    Timeout for each connectivity test. Default is 5.
#>
function Test-NetworkConnectivity {
    param(
        [Parameter(Mandatory)]
        [string]$Target,

        [int]$Port = 80,

        [int]$TimeoutSeconds = 5
    )

    $testScript = {
        param($target, $port, $timeout)

        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connectTask = $tcpClient.ConnectAsync($target, $port)

            # Wait for connection with timeout
            if ($connectTask.Wait($timeout * 1000)) {
                $tcpClient.Close()
                return $true
            }
            else {
                $tcpClient.Close()
                return $false
            }
        }
        catch {
            return $false
        }
    }

    try {
        $result = Invoke-WithRetry -ScriptBlock $testScript -ArgumentList $Target, $Port, $TimeoutSeconds -MaxRetries 2 -TimeoutSeconds ($TimeoutSeconds + 5)
        return $result
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "Network connectivity test failed: $($_.Exception.Message)"
        }
        return $false
    }
}

# HTTP request wrapper with retry
<#
.SYNOPSIS
    Makes HTTP requests with retry logic and timeout handling.
.DESCRIPTION
    Enhanced HTTP client with automatic retry for transient network failures
    and configurable timeouts.
.PARAMETER Uri
    The URI to request.
.PARAMETER Method
    HTTP method. Default is GET.
.PARAMETER TimeoutSeconds
    Request timeout in seconds. Default is 30.
.PARAMETER MaxRetries
    Maximum retry attempts. Default is 3.
#>
function Invoke-HttpRequestWithRetry {
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [string]$Method = 'GET',

        [int]$TimeoutSeconds = 30,

        [int]$MaxRetries = 3
    )

    $requestScript = {
        param($uri, $method, $timeout)

        try {
            $webRequest = [System.Net.WebRequest]::Create($uri)
            $webRequest.Method = $method
            $webRequest.Timeout = $timeout * 1000

            $response = $webRequest.GetResponse()
            $response.Close()
            return $true
        }
        catch {
            throw "HTTP request failed: $($_.Exception.Message)"
        }
    }

    try {
        $result = Invoke-WithRetry -ScriptBlock $requestScript -ArgumentList $Uri, $Method, $TimeoutSeconds -MaxRetries $MaxRetries -TimeoutSeconds ($TimeoutSeconds + 10)
        return $result
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "HTTP request failed after retries: $($_.Exception.Message)"
        }
        return $false
    }
}

# DNS resolution with retry
<#
.SYNOPSIS
    Resolves hostnames with retry logic.
.DESCRIPTION
    DNS resolution with automatic retry for transient DNS failures.
.PARAMETER HostName
    The hostname to resolve.
.PARAMETER TimeoutSeconds
    Timeout for DNS resolution. Default is 10.
#>
function Resolve-HostWithRetry {
    param(
        [Parameter(Mandatory)]
        [string]$HostName,

        [int]$TimeoutSeconds = 10
    )

    $resolveScript = {
        param($hostname, $timeout)

        try {
            $dnsTask = [System.Net.Dns]::GetHostEntryAsync($hostname)
            if ($dnsTask.Wait($timeout * 1000)) {
                return $dnsTask.Result
            }
            else {
                throw "DNS resolution timed out"
            }
        }
        catch {
            throw "DNS resolution failed: $($_.Exception.Message)"
        }
    }

    try {
        $result = Invoke-WithRetry -ScriptBlock $resolveScript -ArgumentList $HostName, $TimeoutSeconds -MaxRetries 2 -TimeoutSeconds ($TimeoutSeconds + 5)
        return $result
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "DNS resolution failed after retries: $($_.Exception.Message)"
        }
        return $null
    }
}

Set-Variable -Name 'NetworkUtilsLoaded' -Value $true -Scope Global -Force
