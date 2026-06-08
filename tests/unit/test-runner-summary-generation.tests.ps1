<#
tests/unit/test-runner-summary-generation.tests.ps1

.SYNOPSIS
    Unit tests for TestSummaryGeneration module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestSummaryGeneration.psm1') -Force -Global

    function script:New-MockTestResult {
        param(
            [int]$Passed = 8,
            [int]$Failed = 0,
            [int]$Skipped = 1
        )

        return [pscustomobject]@{
            TotalCount        = $Passed + $Failed + $Skipped
            PassedCount       = $Passed
            FailedCount       = $Failed
            SkippedCount      = $Skipped
            InconclusiveCount = 0
            NotRunCount       = 0
            Time              = [TimeSpan]::FromSeconds(45)
        }
    }
}

Describe 'TestSummaryGeneration Module' {
    Context 'New-TestExecutionSummary' {
        It 'Builds summary counts and success flag' {
            $result = New-MockTestResult -Failed 0
            $summary = New-TestExecutionSummary -TestResult $result

            $summary.TestResults.Total | Should -Be 9
            $summary.TestResults.Passed | Should -Be 8
            $summary.TestResults.Skipped | Should -Be 1
            $summary.Success | Should -Be $true
            $summary.Timestamp | Should -Not -BeNullOrEmpty
        }

        It 'Adds failure recommendations when tests fail' {
            $result = New-MockTestResult -Passed 5 -Failed 3 -Skipped 0
            $summary = New-TestExecutionSummary -TestResult $result

            $summary.Success | Should -Be $false
            ($summary.Recommendations -join ' ') | Should -Match '3 failed tests'
        }

        It 'Adds performance and CI recommendations when thresholds are exceeded' {
            $result = New-MockTestResult -Failed 0 -Skipped 2
            $performance = @{
                Performance = @{
                    Duration     = [TimeSpan]::FromSeconds(400)
                    PeakMemoryMB = 1200
                }
            }
            $environment = @{
                IsCI = $true
            }

            $summary = New-TestExecutionSummary -TestResult $result -PerformanceData $performance -EnvironmentInfo $environment

            ($summary.Recommendations -join ' ') | Should -Match 'parallel execution'
            ($summary.Recommendations -join ' ') | Should -Match 'High memory usage'
            ($summary.Recommendations -join ' ') | Should -Match '2 skipped tests in CI'
        }
    }
}
