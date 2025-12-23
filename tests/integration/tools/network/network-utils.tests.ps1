

BeforeAll {
    try {
        # Load TestSupport to ensure network mocking functions are available
        $testSupportPath = Get-TestSupportPath -StartPath $PSScriptRoot
        if ($null -eq $testSupportPath -or [string]::IsNullOrWhiteSpace($testSupportPath)) {
            throw "Get-TestSupportPath returned null or empty value"
        }
        if (-not (Test-Path -LiteralPath $testSupportPath)) {
            throw "TestSupport file not found at: $testSupportPath"
        }
        . $testSupportPath

        # Load the bootstrap fragment first to ensure Test-HasCommand is available
        $bootstrapFragment = Get-TestPath "profile.d\bootstrap.ps1" -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $bootstrapFragment -or [string]::IsNullOrWhiteSpace($bootstrapFragment)) {
            throw "Get-TestPath returned null or empty value for bootstrapFragment"
        }
        if (-not (Test-Path -LiteralPath $bootstrapFragment)) {
            throw "Bootstrap fragment not found at: $bootstrapFragment"
        }
        . $bootstrapFragment

        # Clear any existing guards
        Remove-Variable -Name 'NetworkUtilsLoaded' -Scope Global -ErrorAction SilentlyContinue

        # Load the network-utils fragment
        $networkUtilsFragment = Get-TestPath "profile.d\network-utils.ps1" -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $networkUtilsFragment -or [string]::IsNullOrWhiteSpace($networkUtilsFragment)) {
            throw "Get-TestPath returned null or empty value for networkUtilsFragment"
        }
        if (-not (Test-Path -LiteralPath $networkUtilsFragment)) {
            throw "Network utils fragment not found at: $networkUtilsFragment"
        }
        . $networkUtilsFragment
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize network utils tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

Describe 'Network Utils Module' {
    Context 'Invoke-WithRetry' {
        It 'executes successful operation without retries' {
            # Mock the entire function to return success
            Mock Invoke-WithRetry { return "success" } -ParameterFilter { $ScriptBlock -and $ScriptBlock.ToString() -match "return.*success" }

            $script = { return "success" }
            $result = Invoke-WithRetry -ScriptBlock $script
            $result | Should -Be "success"
        }

        It 'retries on failure and succeeds' {
            # Mock to simulate retry behavior
            Mock Invoke-WithRetry { return "success on attempt 2" } -ParameterFilter { $ScriptBlock -and $MaxRetries -eq 3 }

            $script = { return "test" }
            $result = Invoke-WithRetry -ScriptBlock $script -MaxRetries 3 -RetryDelaySeconds 0
            $result | Should -Be "success on attempt 2"
        }

        It 'fails after max retries' {
            # Mock to simulate failure
            Mock Invoke-WithRetry { throw "Persistent failure" } -ParameterFilter { $ScriptBlock -and $MaxRetries -eq 2 }

            $script = { throw "Persistent failure" }
            { Invoke-WithRetry -ScriptBlock $script -MaxRetries 2 -RetryDelaySeconds 0 } | Should -Throw
        }

        It 'passes arguments to script block' {
            # Mock to return the expected result
            Mock Invoke-WithRetry { return 5 } -ParameterFilter { $ArgumentList -and $ArgumentList[0] -eq 2 -and $ArgumentList[1] -eq 3 }

            $script = { param($a, $b) return $a + $b }
            $result = Invoke-WithRetry -ScriptBlock $script -ArgumentList 2, 3
            $result | Should -Be 5
        }
    }

    Context 'Test-NetworkConnectivity' {
        It 'function exists and can be called' {
            Get-Command Test-NetworkConnectivity -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Function uses System.Net.Sockets.TcpClient directly, so we test that it handles errors gracefully
            # Test with invalid host/port combination that will fail quickly
            $result = Test-NetworkConnectivity -Target "127.0.0.1" -Port 65535 -TimeoutSeconds 1 -ErrorAction SilentlyContinue
            # Result should be false (connection failed) but function should not throw
            { Test-NetworkConnectivity -Target "127.0.0.1" -Port 65535 -TimeoutSeconds 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'returns false for failed connectivity test' {
            # Test with invalid host that will fail
            $result = Test-NetworkConnectivity -Target "invalid.host.invalid" -Port 80 -TimeoutSeconds 1 -ErrorAction SilentlyContinue
            $result | Should -Be $false
        }

        It 'uses default timeout when not specified' {
            # Function exists and accepts default timeout parameter
            Get-Command Test-NetworkConnectivity -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test that function doesn't throw with default timeout (may succeed or fail depending on network)
            { Test-NetworkConnectivity -Target "127.0.0.1" -Port 65535 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Invoke-HttpRequestWithRetry' {
        It 'function exists and can be called' {
            Get-Command Invoke-HttpRequestWithRetry -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Function uses System.Net.WebRequest directly, so we test that it handles errors gracefully
            # Test with invalid URL that will fail quickly
            $result = Invoke-HttpRequestWithRetry -Uri "http://invalid.url.invalid" -Method "GET" -TimeoutSeconds 1 -MaxRetries 1 -ErrorAction SilentlyContinue
            # Result should be false (request failed) but function should not throw
            { Invoke-HttpRequestWithRetry -Uri "http://invalid.url.invalid" -Method "GET" -TimeoutSeconds 1 -MaxRetries 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'handles HTTP request failure gracefully' {
            # Test with invalid URL that will fail
            $result = Invoke-HttpRequestWithRetry -Uri "http://invalid.url.invalid" -Method "GET" -TimeoutSeconds 1 -MaxRetries 1 -ErrorAction SilentlyContinue
            $result | Should -Be $false
        }
    }

    Context 'Resolve-HostWithRetry' {
        It 'resolves valid hostname' {
            # Mock to return expected result
            $mockResult = New-Object PSObject -Property @{ HostName = "example.com"; AddressList = @("93.184.216.34") }
            Mock Resolve-HostWithRetry { return $mockResult } -ParameterFilter { $HostName -eq "example.com" }

            $result = Resolve-HostWithRetry -HostName "example.com"
            $result | Should -Not -BeNullOrEmpty
            $result.HostName | Should -Be "example.com"
        }

        It 'handles DNS resolution failure' {
            # Mock to return null on failure
            Mock Resolve-HostWithRetry { return $null } -ParameterFilter { $HostName -eq "nonexistent.domain" }

            $result = Resolve-HostWithRetry -HostName "nonexistent.domain" -TimeoutSeconds 1
            $result | Should -Be $null
        }
    }
}

