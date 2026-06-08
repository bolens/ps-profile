<#
tests/unit/library-retry-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Retry callback resilience and pattern matching.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Retry.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module Retry -ErrorAction SilentlyContinue -Force
}

Describe 'Retry extended scenarios' {
    Context 'Invoke-WithRetry' {
        It 'Continues retrying when the OnRetry callback throws' {
            $script:attemptCounter = 0

            $result = Invoke-WithRetry -ScriptBlock {
                $script:attemptCounter++
                if ($script:attemptCounter -lt 2) {
                    throw 'transient failure'
                }

                return 'recovered'
            } -MaxRetries 2 -RetryDelaySeconds 0 -OnRetry {
                throw 'callback failure'
            }

            $result | Should -Be 'recovered'
            $script:attemptCounter | Should -Be 2
        }

        It 'Fails after a single attempt when MaxRetries is zero' {
            $script:attemptCounter = 0

            {
                Invoke-WithRetry -ScriptBlock {
                    $script:attemptCounter++
                    throw 'immediate failure'
                } -MaxRetries 0 -RetryDelaySeconds 0 -ErrorAction SilentlyContinue
            } | Should -Throw

            $script:attemptCounter | Should -Be 1
        }
    }

    Context 'Test-IsRetryableError' {
        It 'Treats busy and locked messages as retryable' {
            Test-IsRetryableError -Exception ([Exception]::new('Resource is busy')) | Should -Be $true
            Test-IsRetryableError -Exception ([Exception]::new('File is locked by another process')) | Should -Be $true
        }
    }

    Context 'Get-RetryDelay' {
        It 'Calculates exponential delay for later attempts' {
            $delay = Get-RetryDelay -Attempt 4 -BaseDelaySeconds 1 -ExponentialBackoff

            $delay | Should -Be 8
        }
    }
}
