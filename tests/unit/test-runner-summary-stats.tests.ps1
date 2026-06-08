<#
tests/unit/test-runner-summary-stats.tests.ps1

.SYNOPSIS
    Unit tests for TestSummaryStats module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestSummaryStats.psm1') -Force -Global

    function script:New-MockTestResult {
        param(
            [int]$Passed = 8,
            [int]$Failed = 2,
            [int]$Skipped = 1,
            [int]$NotRun = 0
        )

        $total = $Passed + $Failed + $Skipped + $NotRun
        $tests = @(
            [pscustomobject]@{
                Name     = 'Slow passing test'
                Duration = [TimeSpan]::FromSeconds(5)
                Result   = 'Passed'
            },
            [pscustomobject]@{
                Name        = 'Failed assertion test'
                Duration    = [TimeSpan]::FromSeconds(3)
                Result      = 'Failed'
                ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [Exception]::new('Expected 1 but got 2'),
                    'PesterAssertionFailed',
                    'NotSpecified',
                    $null
                )
            },
            [pscustomobject]@{
                Name        = 'Another failure'
                Duration    = [TimeSpan]::FromSeconds(1)
                Result      = 'Failed'
                ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [Exception]::new('Expected 1 but got 2'),
                    'PesterAssertionFailed',
                    'NotSpecified',
                    $null
                )
            }
        )

        return [pscustomobject]@{
            TotalCount   = $total
            PassedCount  = $Passed
            FailedCount  = $Failed
            SkippedCount = $Skipped
            NotRunCount  = $NotRun
            Duration     = [TimeSpan]::FromSeconds(12)
            Tests        = $tests
        }
    }
}

Describe 'TestSummaryStats Module' {
    Context 'Get-TestSummaryStatistics' {
        It 'Returns counts and slowest tests from a Pester result' {
            $result = New-MockTestResult
            $stats = Get-TestSummaryStatistics -TestResult $result -ShowSlowest 2

            $stats.TotalTests | Should -Be 11
            $stats.PassedTests | Should -Be 8
            $stats.FailedTests | Should -Be 2
            $stats.SkippedTests | Should -Be 1
            $stats.SlowestTests.Count | Should -Be 2
            $stats.SlowestTests[0].Name | Should -Be 'Slow passing test'
            $stats.FailedTestNames.Count | Should -Be 2
        }

        It 'Groups common failure patterns' {
            $result = New-MockTestResult
            $stats = Get-TestSummaryStatistics -TestResult $result

            $patterns = @($stats.FailurePatterns)
            $patterns.Count | Should -BeGreaterThan 0
            $patterns[0]['Pattern'] | Should -Be 'Expected 1 but got 2'
            $patterns[0]['Count'] | Should -Be 2
        }

        It 'Includes performance data when provided' {
            $result = New-MockTestResult
            $perf = @{
                PeakMemory    = 256MB
                AverageMemory = 128MB
                PeakCPU       = 90
                AverageCPU    = 45
            }

            $stats = Get-TestSummaryStatistics -TestResult $result -PerformanceData $perf

            $stats.PerformanceData.PeakMemory | Should -Be 256MB
            $stats.PerformanceData.AverageCPU | Should -Be 45
        }
    }

    Context 'Show-TestSummaryStatistics' {
        It 'Writes summary sections without error' {
            $result = New-MockTestResult
            $stats = Get-TestSummaryStatistics -TestResult $result

            { Show-TestSummaryStatistics -Statistics $stats -ShowSlowest -ShowFailurePatterns } | Should -Not -Throw
        }
    }
}
