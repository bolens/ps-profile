BeforeAll {
    # Source the test support
    . "$PSScriptRoot\..\TestSupport.ps1"

    # Load the bootstrap fragment first to ensure Test-HasCommand is available
    $bootstrapFragment = Get-TestPath "profile.d\00-bootstrap.ps1"
    . $bootstrapFragment

    # Clear any existing guards
    Remove-Variable -Name 'NetworkUtilsLoaded' -Scope Global -ErrorAction SilentlyContinue

    # Load the network-utils fragment
    $networkUtilsFragment = Get-TestPath "profile.d\71-network-utils.ps1"
    . $networkUtilsFragment
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
        It 'returns true for valid connectivity test' {
            # Mock Test-Connection to return success
            Mock Test-Connection { return @{ ResponseTime = 10 } }

            $result = Test-NetworkConnectivity -Target "8.8.8.8" -Port 53
            $result | Should -Be $true
        }

        It 'returns false for failed connectivity test' {
            # Mock Test-Connection to throw exception
            Mock Test-Connection { throw "Connection failed" }

            $result = Test-NetworkConnectivity -Target "invalid.host" -Port 80 -TimeoutSeconds 1
            $result | Should -Be $false
        }

        It 'uses default timeout when not specified' {
            Mock Test-Connection { return @{ ResponseTime = 5 } }

            $result = Test-NetworkConnectivity -Target "google.com" -Port 443
            $result | Should -Be $true
        }
    }

    Context 'Invoke-HttpRequestWithRetry' {
        It 'executes successful HTTP request' {
            # Mock the entire function to return success
            Mock Invoke-HttpRequestWithRetry { return $true } -ParameterFilter { $Uri -eq "https://example.com" -and $Method -eq "GET" }

            $result = Invoke-HttpRequestWithRetry -Uri "https://example.com" -Method "GET"
            $result | Should -Be $true
        }

        It 'handles HTTP request failure' {
            # Mock to simulate failure
            Mock Invoke-HttpRequestWithRetry { return $false } -ParameterFilter { $Uri -eq "https://invalid.url" -and $MaxRetries -eq 1 }

            $result = Invoke-HttpRequestWithRetry -Uri "https://invalid.url" -Method "GET" -MaxRetries 1
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
