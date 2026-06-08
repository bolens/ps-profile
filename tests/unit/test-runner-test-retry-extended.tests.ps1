<#
tests/unit/test-runner-test-retry-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestRetry failure and backoff behavior.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestRetry.psm1') -Force -Global
}

Describe 'TestRetry extended scenarios' {
    Context 'Invoke-TestWithRetry' {
        It 'Throws after exhausting all retry attempts' {
            $script:attemptCounter = 0

            {
                Invoke-TestWithRetry -ScriptBlock {
                    $script:attemptCounter++
                    throw 'always fails'
                } -MaxRetries 1 -RetryDelaySeconds 0 -WarningAction SilentlyContinue
            } | Should -Throw '*always fails*'

            $script:attemptCounter | Should -Be 2
        }

        It 'Retries with exponential backoff until success' {
            $script:attemptCounter = 0

            $result = Invoke-TestWithRetry -ScriptBlock {
                $script:attemptCounter++
                if ($script:attemptCounter -lt 3) {
                    throw 'transient failure'
                }

                return @{ PassedCount = 1; FailedCount = 0 }
            } -MaxRetries 3 -RetryDelaySeconds 0 -ExponentialBackoff -WarningAction SilentlyContinue

            $script:attemptCounter | Should -Be 3
            $result.PassedCount | Should -Be 1
        }

        It 'Does not retry failed test counts when RetryOnFailure is not set' {
            $script:attemptCounter = 0

            $result = Invoke-TestWithRetry -ScriptBlock {
                $script:attemptCounter++
                return @{ PassedCount = 0; FailedCount = 2 }
            } -MaxRetries 3 -RetryDelaySeconds 0 -WarningAction SilentlyContinue

            $script:attemptCounter | Should -Be 1
            $result.FailedCount | Should -Be 2
        }
    }
}
