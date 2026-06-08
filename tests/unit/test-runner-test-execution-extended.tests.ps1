<#
tests/unit/test-runner-test-execution-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for test execution summary recommendations and retry flags.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestSummaryGeneration.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestRetry.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputSanitizer.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputInterceptor.psm1') -Force -Global

    $script:RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Initialize-OutputUtils -RepoRoot $script:RepoRoot

    function script:New-MockTestResult {
        param(
            [int]$Failed = 0,
            [int]$Skipped = 0
        )

        return @{
            TotalCount        = 10
            PassedCount       = 10 - $Failed - $Skipped
            FailedCount       = $Failed
            SkippedCount      = $Skipped
            InconclusiveCount = 0
            NotRunCount       = 0
            Time              = [TimeSpan]::FromSeconds(30)
        }
    }
}

Describe 'Test execution extended scenarios' {
    Context 'New-TestExecutionSummary' {
        It 'Marks Success when no tests failed' {
            $summary = New-TestExecutionSummary -TestResult (New-MockTestResult) -EnvironmentInfo @{ IsCI = $false }

            $summary.Success | Should -Be $true
            @($summary.Recommendations).Count | Should -Be 0
        }

        It 'Recommends reviewing skipped tests in CI environments' {
            $summary = New-TestExecutionSummary -TestResult (New-MockTestResult -Skipped 2) -EnvironmentInfo @{ IsCI = $true }

            $summary.Recommendations | Should -Contain 'Review 2 skipped tests in CI environment'
        }

        It 'Recommends parallel execution for long-running suites' {
            $performance = @{
                Performance = @{
                    Duration     = [TimeSpan]::FromSeconds(400)
                    PeakMemoryMB = 100
                }
            }

            $summary = New-TestExecutionSummary -TestResult (New-MockTestResult) -PerformanceData $performance -EnvironmentInfo @{ IsCI = $false }

            @($summary.Recommendations | Where-Object { $_ -like '*parallel execution*' }).Count | Should -Be 1
        }

        It 'Recommends investigating high memory usage' {
            $performance = @{
                Performance = @{
                    Duration     = [TimeSpan]::FromSeconds(30)
                    PeakMemoryMB = 1500
                }
            }

            $summary = New-TestExecutionSummary -TestResult (New-MockTestResult) -PerformanceData $performance -EnvironmentInfo @{ IsCI = $false }

            @($summary.Recommendations | Where-Object { $_ -like '*High memory usage*' }).Count | Should -Be 1
        }
    }

    Context 'Invoke-TestWithRetry' {
        It 'Completes when SuppressRetryWarnings is enabled and retries succeed' {
            $script:attemptCounter = 0

            $result = Invoke-TestWithRetry -ScriptBlock {
                $script:attemptCounter++
                if ($script:attemptCounter -lt 2) {
                    throw 'transient setup failure'
                }

                return @{ PassedCount = 1; FailedCount = 0 }
            } -MaxRetries 2 -RetryDelaySeconds 0 -SuppressRetryWarnings -WarningAction SilentlyContinue

            $script:attemptCounter | Should -Be 2
            $result.PassedCount | Should -Be 1
        }
    }
}
