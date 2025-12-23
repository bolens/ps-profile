<#
.SYNOPSIS
    Unit tests for Retry module.

.DESCRIPTION
    Tests for Invoke-WithRetry, Test-IsRetryableError, and Get-RetryDelay functions.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'scripts' 'lib' 'core' 'Retry.psm1'
    Import-Module $modulePath -Force -DisableNameChecking
}

AfterAll {
    Remove-Module Retry -Force -ErrorAction SilentlyContinue
}

Describe 'Invoke-WithRetry' {
    It 'Returns result when scriptblock succeeds on first attempt' {
        $result = Invoke-WithRetry -ScriptBlock { return 'success' } -MaxRetries 3
        $result | Should -Be 'success'
    }

    It 'Retries and succeeds on second attempt' {
        $script:attempt = 0
        $result = Invoke-WithRetry -ScriptBlock {
            $script:attempt++
            if ($script:attempt -eq 1) {
                throw 'First attempt failed'
            }
            return 'success'
        } -MaxRetries 3 -RetryDelaySeconds 0.1
        $result | Should -Be 'success'
        $script:attempt | Should -Be 2
    }

    It 'Throws after max retries exceeded' {
        { Invoke-WithRetry -ScriptBlock { throw 'Always fails' } -MaxRetries 2 -RetryDelaySeconds 0.1 } | Should -Throw
    }

    It 'Uses exponential backoff when specified' {
        $script:delays = @()
        $script:onRetryCalled = $false
        $onRetry = {
            param($Attempt, $MaxRetries, $DelaySeconds, $Exception)
            $script:delays += $DelaySeconds
            $script:onRetryCalled = $true
        }

        $script:attempt = 0
        try {
            Invoke-WithRetry -ScriptBlock {
                $script:attempt++
                throw 'Fail'
            } -MaxRetries 2 -RetryDelaySeconds 1 -ExponentialBackoff -OnRetry $onRetry -ErrorAction SilentlyContinue
        }
        catch {
            # Expected to fail
        }

        $script:onRetryCalled | Should -Be $true
        $script:delays.Count | Should -BeGreaterOrEqual 1
        # First retry delay should be 1 second (1 * 2^0), second should be 2 seconds (1 * 2^1)
        if ($script:delays.Count -ge 1) {
            $script:delays[0] | Should -Be 1
        }
    }

    It 'Uses linear backoff when specified' {
        $delays = @()
        $onRetry = {
            param($Attempt, $MaxRetries, $DelaySeconds, $Exception)
            $script:delays += $DelaySeconds
        }

        $attempt = 0
        try {
            Invoke-WithRetry -ScriptBlock {
                $script:attempt++
                throw 'Fail'
            } -MaxRetries 2 -RetryDelaySeconds 1 -LinearBackoff -OnRetry $onRetry -ErrorAction SilentlyContinue
        }
        catch {
            # Expected to fail
        }

        if ($delays.Count -ge 1) {
            $delays[0] | Should -Be 1
        }
        if ($delays.Count -ge 2) {
            $delays[1] | Should -Be 2
        }
    }

    It 'Respects RetryCondition - retries retryable errors' {
        $script:attempt = 0
        $result = Invoke-WithRetry -ScriptBlock {
            $script:attempt++
            if ($script:attempt -eq 1) {
                throw [Exception]::new('timeout error')
            }
            return 'success'
        } -MaxRetries 3 -RetryDelaySeconds 0.1 -RetryCondition {
            param($ErrorRecord)
            $ErrorRecord.Exception.Message -match 'timeout'
        }
        $result | Should -Be 'success'
        $script:attempt | Should -Be 2
    }

    It 'Respects RetryCondition - does not retry non-retryable errors' {
        { Invoke-WithRetry -ScriptBlock {
                throw [Exception]::new('permanent error')
            } -MaxRetries 3 -RetryDelaySeconds 0.1 -RetryCondition {
                param($Exception)
                $Exception.Message -match 'timeout'
            } } | Should -Throw
    }

    It 'Respects MaxDelaySeconds cap' {
        $delays = @()
        $onRetry = {
            param($Attempt, $MaxRetries, $DelaySeconds, $Exception)
            $script:delays += $DelaySeconds
        }

        $attempt = 0
        try {
            Invoke-WithRetry -ScriptBlock {
                $script:attempt++
                throw 'Fail'
            } -MaxRetries 5 -RetryDelaySeconds 100 -ExponentialBackoff -MaxDelaySeconds 10 -OnRetry $onRetry -ErrorAction SilentlyContinue
        }
        catch {
            # Expected to fail
        }

        # All delays should be capped at 10 seconds
        foreach ($delay in $delays) {
            $delay | Should -BeLessOrEqual 10
        }
    }

    It 'Handles zero retries' {
        $result = Invoke-WithRetry -ScriptBlock { return 'success' } -MaxRetries 0
        $result | Should -Be 'success'
    }

    It 'Handles scriptblocks with return values' {
        $obj = [PSCustomObject]@{ Name = 'Test'; Value = 123 }
        $result = Invoke-WithRetry -ScriptBlock { return $obj } -MaxRetries 1
        $result.Name | Should -Be 'Test'
        $result.Value | Should -Be 123
    }
}

Describe 'Test-IsRetryableError' {
    It 'Returns true for timeout errors' {
        $ex = [Exception]::new('Operation timeout occurred')
        Test-IsRetryableError -Exception $ex | Should -Be $true
    }

    It 'Returns true for network errors' {
        $ex = [Exception]::new('Network connection failed')
        Test-IsRetryableError -Exception $ex | Should -Be $true
    }

    It 'Returns true for connection errors' {
        $ex = [Exception]::new('Connection refused')
        Test-IsRetryableError -Exception $ex | Should -Be $true
    }

    It 'Returns true for DNS errors' {
        $ex = [Exception]::new('DNS resolution failed')
        Test-IsRetryableError -Exception $ex | Should -Be $true
    }

    It 'Returns false for non-retryable errors' {
        $ex = [Exception]::new('Invalid parameter')
        Test-IsRetryableError -Exception $ex | Should -Be $false
    }

    It 'Returns false for empty error message' {
        $ex = [Exception]::new('')
        Test-IsRetryableError -Exception $ex | Should -Be $false
    }

    It 'Returns false for null error message' {
        $ex = [Exception]::new($null)
        Test-IsRetryableError -Exception $ex | Should -Be $false
    }

    It 'Uses custom retryable patterns' {
        $ex = [Exception]::new('Custom retryable error')
        Test-IsRetryableError -Exception $ex -RetryablePatterns @('custom', 'retryable') | Should -Be $true
    }

    It 'Is case-insensitive' {
        $ex = [Exception]::new('TIMEOUT ERROR')
        Test-IsRetryableError -Exception $ex | Should -Be $true
    }

    It 'Matches partial patterns' {
        $ex = [Exception]::new('Connection timeout occurred')
        Test-IsRetryableError -Exception $ex | Should -Be $true
    }
}

Describe 'Get-RetryDelay' {
    It 'Returns base delay for fixed backoff' {
        $delay = Get-RetryDelay -Attempt 1 -BaseDelaySeconds 2
        $delay | Should -Be 2
    }

    It 'Returns same delay for all attempts with fixed backoff' {
        $delay1 = Get-RetryDelay -Attempt 1 -BaseDelaySeconds 2
        $delay2 = Get-RetryDelay -Attempt 2 -BaseDelaySeconds 2
        $delay3 = Get-RetryDelay -Attempt 3 -BaseDelaySeconds 2
        $delay1 | Should -Be 2
        $delay2 | Should -Be 2
        $delay3 | Should -Be 2
    }

    It 'Returns exponential delay with exponential backoff' {
        $delay1 = Get-RetryDelay -Attempt 1 -BaseDelaySeconds 1 -ExponentialBackoff
        $delay2 = Get-RetryDelay -Attempt 2 -BaseDelaySeconds 1 -ExponentialBackoff
        $delay3 = Get-RetryDelay -Attempt 3 -BaseDelaySeconds 1 -ExponentialBackoff
        $delay1 | Should -Be 1   # 1 * 2^0
        $delay2 | Should -Be 2   # 1 * 2^1
        $delay3 | Should -Be 4   # 1 * 2^2
    }

    It 'Returns linear delay with linear backoff' {
        $delay1 = Get-RetryDelay -Attempt 1 -BaseDelaySeconds 2 -LinearBackoff
        $delay2 = Get-RetryDelay -Attempt 2 -BaseDelaySeconds 2 -LinearBackoff
        $delay3 = Get-RetryDelay -Attempt 3 -BaseDelaySeconds 2 -LinearBackoff
        $delay1 | Should -Be 2   # 2 * 1
        $delay2 | Should -Be 4   # 2 * 2
        $delay3 | Should -Be 6   # 2 * 3
    }

    It 'Respects MaxDelaySeconds cap' {
        $delay = Get-RetryDelay -Attempt 10 -BaseDelaySeconds 10 -ExponentialBackoff -MaxDelaySeconds 60
        $delay | Should -BeLessOrEqual 60
    }

    It 'Caps exponential backoff at MaxDelaySeconds' {
        $delay = Get-RetryDelay -Attempt 10 -BaseDelaySeconds 10 -ExponentialBackoff -MaxDelaySeconds 60
        $delay | Should -Be 60
    }

    It 'Caps linear backoff at MaxDelaySeconds' {
        $delay = Get-RetryDelay -Attempt 100 -BaseDelaySeconds 1 -LinearBackoff -MaxDelaySeconds 60
        $delay | Should -Be 60
    }

    It 'Handles zero base delay' {
        $delay = Get-RetryDelay -Attempt 1 -BaseDelaySeconds 0
        $delay | Should -Be 0
    }

    It 'Handles fractional delays' {
        $delay = Get-RetryDelay -Attempt 1 -BaseDelaySeconds 0.5
        $delay | Should -Be 0.5
    }
}

