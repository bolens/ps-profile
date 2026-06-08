<#
tests/unit/test-runner-test-analysis-trends-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestAnalysis trend and recommendation helpers.
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
    Import-Module (Join-Path $modulePath 'TestAnalysis.psm1') -Force -Global
}

Describe 'TestAnalysis extended scenarios' {
    Context 'Analyze-TestTrends' {
        It 'Computes average duration across current and historical runs' {
            $current = [pscustomobject]@{
                TotalCount  = 10
                FailedCount = 1
                Time        = [TimeSpan]::FromSeconds(10)
            }
            $historical = @(
                @{ FailedCount = 2; TotalCount = 10; Time = [TimeSpan]::FromSeconds(6) },
                @{ FailedCount = 0; TotalCount = 10; Time = [TimeSpan]::FromSeconds(8) }
            )

            $trends = Analyze-TestTrends -CurrentResult $current -HistoricalData $historical

            $trends.RecentRuns | Should -Be 1
            $trends.AverageFailureRate | Should -Be 0.1
            $trends.AverageDuration.TotalSeconds | Should -Be 10
            $trends.StabilityTrend | Should -Be 'Unknown'
        }

        It 'Returns zero failure rate when current run has no tests' {
            $current = [pscustomobject]@{
                TotalCount  = 0
                FailedCount = 0
                Time        = [TimeSpan]::Zero
            }

            $trends = Analyze-TestTrends -CurrentResult $current -HistoricalData @()

            $trends.AverageFailureRate | Should -Be 0
        }
    }

    Context 'Get-ComprehensiveRecommendations' {
        It 'Returns no recommendations for healthy report data' {
            $report = [pscustomobject]@{
                TestResults = [pscustomobject]@{
                    SuccessRate = 98
                    FailedTests = 1
                }
                Performance = [pscustomobject]@{
                    PerformanceGrade = 'A'
                    MemoryUsage      = [pscustomobject]@{ PeakMB = 256 }
                }
                QualityMetrics = [pscustomobject]@{
                    OverallQuality = 92
                }
            }

            Get-ComprehensiveRecommendations -Report $report | Should -Be @()
        }

        It 'Flags critical performance and quality issues together' {
            $report = [pscustomobject]@{
                TestResults = [pscustomobject]@{
                    SuccessRate = 70
                    FailedTests = 8
                }
                Performance = [pscustomobject]@{
                    PerformanceGrade = 'F'
                    MemoryUsage      = [pscustomobject]@{ PeakMB = 2048 }
                }
                QualityMetrics = [pscustomobject]@{
                    OverallQuality = 55
                }
            }

            $recommendations = @(Get-ComprehensiveRecommendations -Report $report)

            $recommendations.Count | Should -BeGreaterThan 3
            ($recommendations -join ' ') | Should -Match 'Improve test success rate'
            ($recommendations -join ' ') | Should -Match 'Critical performance issues'
            ($recommendations -join ' ') | Should -Match 'High memory usage'
            ($recommendations -join ' ') | Should -Match 'Overall test quality'
        }
    }
}
