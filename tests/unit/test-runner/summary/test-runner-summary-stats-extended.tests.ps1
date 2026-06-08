<#
tests/unit/test-runner-summary-stats-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestSummaryStats edge cases.
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
    Import-Module (Join-Path $modulePath 'TestSummaryStats.psm1') -Force -Global
}

Describe 'TestSummaryStats extended scenarios' {
    Context 'Get-TestSummaryStatistics' {
        It 'Returns empty detail collections when no per-test data exists' {
            $result = [pscustomobject]@{
                TotalCount   = 5
                PassedCount  = 5
                FailedCount  = 0
                SkippedCount = 0
                NotRunCount  = 0
                Duration     = [TimeSpan]::FromSeconds(2)
                Tests        = $null
            }

            $stats = Get-TestSummaryStatistics -TestResult $result

            @($stats.SlowestTests).Count | Should -Be 0
            @($stats.FailedTestNames).Count | Should -Be 0
            @($stats.FailurePatterns).Count | Should -Be 0
        }

        It 'Limits slowest test output to ShowSlowest count' {
            $tests = 1..6 | ForEach-Object {
                [pscustomobject]@{
                    Name     = "Timed test $_"
                    Duration = [TimeSpan]::FromSeconds($_)
                    Result   = 'Passed'
                }
            }

            $result = [pscustomobject]@{
                TotalCount   = 6
                PassedCount  = 6
                FailedCount  = 0
                SkippedCount = 0
                NotRunCount  = 0
                Duration     = [TimeSpan]::FromSeconds(21)
                Tests        = $tests
            }

            $stats = Get-TestSummaryStatistics -TestResult $result -ShowSlowest 2

            @($stats.SlowestTests).Count | Should -Be 2
            $stats.SlowestTests[0].Name | Should -Be 'Timed test 6'
        }

        It 'Omits failure patterns when failed tests have no error records' {
            $result = [pscustomobject]@{
                TotalCount   = 1
                PassedCount  = 0
                FailedCount  = 1
                SkippedCount = 0
                NotRunCount  = 0
                Duration     = [TimeSpan]::FromSeconds(1)
                Tests        = @(
                    [pscustomobject]@{
                        Name     = 'Failed without error record'
                        Duration = [TimeSpan]::FromSeconds(1)
                        Result   = 'Failed'
                    }
                )
            }

            $stats = Get-TestSummaryStatistics -TestResult $result
            @($stats.FailurePatterns).Count | Should -Be 0
            @($stats.FailedTestNames).Count | Should -Be 1
        }
    }

    Context 'Show-TestSummaryStatistics' {
        It 'Writes performance metrics when statistics include them' {
            $stats = @{
                TotalTests      = 10
                PassedTests     = 10
                FailedTests     = 0
                SkippedTests    = 0
                NotRunTests     = 0
                Duration        = [TimeSpan]::FromSeconds(4)
                SlowestTests    = @()
                FailedTestNames = @()
                FailurePatterns = @()
                PerformanceData = @{
                    PeakMemory    = 128MB
                    AverageMemory = 64MB
                    PeakCPU       = 80
                    AverageCPU    = 35
                }
            }

            { Show-TestSummaryStatistics -Statistics $stats } | Should -Not -Throw
        }
    }
}
