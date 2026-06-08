<#
tests/unit/test-runner-summary-generation-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for New-TestExecutionSummary recommendation logic.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestSummaryGeneration.psm1') -Force -Global

    function script:New-MockTestResult {
        param(
            [int]$Passed = 10,
            [int]$Failed = 0,
            [int]$Skipped = 0,
            [double]$Seconds = 30
        )

        return [pscustomobject]@{
            TotalCount        = $Passed + $Failed + $Skipped
            PassedCount       = $Passed
            FailedCount       = $Failed
            SkippedCount      = $Skipped
            InconclusiveCount = 0
            NotRunCount       = 0
            Time              = [TimeSpan]::FromSeconds($Seconds)
        }
    }
}

Describe 'TestSummaryGeneration extended scenarios' {
    Context 'New-TestExecutionSummary' {
        It 'Leaves recommendations empty for clean successful runs' {
            $result = New-MockTestResult
            $summary = New-TestExecutionSummary -TestResult $result

            @($summary.Recommendations).Count | Should -Be 0
            $summary.Environment | Should -BeNullOrEmpty
            $summary.Performance | Should -BeNullOrEmpty
        }

        It 'Omits CI skip guidance when environment info is absent' {
            $result = New-MockTestResult -Skipped 3
            $summary = New-TestExecutionSummary -TestResult $result

            @($summary.Recommendations | Where-Object { $_ -match 'CI environment' }).Count | Should -Be 0
        }

        It 'Adds CI skip guidance when running in CI with skipped tests' {
            $result = New-MockTestResult -Skipped 2
            $environment = @{ IsCI = $true }

            $summary = New-TestExecutionSummary -TestResult $result -EnvironmentInfo $environment

            ($summary.Recommendations -join ' ') | Should -Match 'skipped tests in CI environment'
        }

        It 'Includes environment and performance payloads when supplied' {
            $result = New-MockTestResult
            $environment = @{ IsCI = $false; CIProvider = $null }
            $performance = @{
                Performance = @{
                    Duration     = [TimeSpan]::FromSeconds(90)
                    PeakMemoryMB = 256
                }
            }

            $summary = New-TestExecutionSummary -TestResult $result -EnvironmentInfo $environment -PerformanceData $performance

            $summary.Environment.IsCI | Should -Be $false
            $summary.Performance.Performance.PeakMemoryMB | Should -Be 256
        }
    }
}
