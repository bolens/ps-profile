<#
tests/unit/test-runner-test-retry.tests.ps1

.SYNOPSIS
    Dedicated unit tests for TestRetry module behaviors.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestRetry.psm1') -Force -Global
}

Describe 'TestRetry Module' {
    Context 'Invoke-TestWithRetry' {
        It 'Suppresses retry warnings while still retrying failures' {
            $script:attemptCounter = 0

            $result = Invoke-TestWithRetry -ScriptBlock {
                $script:attemptCounter++
                if ($script:attemptCounter -lt 2) {
                    return @{ PassedCount = 0; FailedCount = 1 }
                }

                return @{ PassedCount = 1; FailedCount = 0 }
            } -MaxRetries 2 -RetryOnFailure -RetryDelaySeconds 0 -SuppressRetryWarnings -WarningAction SilentlyContinue

            $script:attemptCounter | Should -Be 2
            $result.FailedCount | Should -Be 0
        }

        It 'Uses linear delay when exponential backoff is disabled' {
            $script:attemptCounter = 0
            $script:delayMarkers = @()

            {
                Invoke-TestWithRetry -ScriptBlock {
                    $script:attemptCounter++
                    if ($script:attemptCounter -lt 3) {
                        $script:delayMarkers += Get-Date
                        throw 'transient'
                    }

                    return @{ PassedCount = 1; FailedCount = 0 }
                } -MaxRetries 2 -RetryDelaySeconds 0 -WarningAction SilentlyContinue
            } | Should -Not -Throw

            $script:attemptCounter | Should -Be 3
        }
    }
}
