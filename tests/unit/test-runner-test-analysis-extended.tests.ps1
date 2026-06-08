<#
tests/unit/test-runner-test-analysis-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestAnalysis trend and recommendation helpers.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestAnalysis.psm1') -Force -Global
}

Describe 'TestAnalysis extended scenarios' {
    Context 'Analyze-TestTrends' {
        It 'Computes average failure rate from the current result' {
            $current = [pscustomobject]@{
                TotalCount  = 20
                FailedCount = 5
                Time        = [TimeSpan]::FromSeconds(120)
            }

            $trends = Analyze-TestTrends -CurrentResult $current -HistoricalData @()

            $trends.AverageFailureRate | Should -Be 0.25
            $trends.AverageDuration | Should -Be $current.Time
            $trends.RecentRuns | Should -Be 1
        }

        It 'Returns zero failure rate for empty result sets' {
            $current = [pscustomobject]@{
                TotalCount  = 0
                FailedCount = 0
                Time        = [TimeSpan]::Zero
            }

            (Analyze-TestTrends -CurrentResult $current -HistoricalData $null).AverageFailureRate | Should -Be 0
        }
    }

    Context 'Get-ComprehensiveRecommendations' {
        It 'Returns no recommendations for healthy reports' {
            $report = [pscustomobject]@{
                TestResults = [pscustomobject]@{
                    SuccessRate  = 98
                    FailedTests  = 0
                }
                Performance = [pscustomobject]@{
                    PerformanceGrade = 'A'
                    MemoryUsage      = [pscustomobject]@{ PeakMB = 256 }
                }
                QualityMetrics = [pscustomobject]@{
                    OverallQuality = 92
                }
            }

            @(Get-ComprehensiveRecommendations -Report $report) | Should -Be @()
        }

        It 'Combines quality, performance, and failure recommendations' {
            $report = [pscustomobject]@{
                TestResults = [pscustomobject]@{
                    SuccessRate  = 75
                    FailedTests  = 8
                }
                Performance = [pscustomobject]@{
                    PerformanceGrade = 'F'
                    MemoryUsage      = [pscustomobject]@{ PeakMB = 1500 }
                }
                QualityMetrics = [pscustomobject]@{
                    OverallQuality = 55
                }
            }

            $recommendations = @(Get-ComprehensiveRecommendations -Report $report)

            @($recommendations).Count | Should -BeGreaterThan 3
            ($recommendations -join ' ') | Should -Match 'success rate'
            ($recommendations -join ' ') | Should -Match '8 failing tests'
            ($recommendations -join ' ') | Should -Match 'Critical performance'
            ($recommendations -join ' ') | Should -Match 'High memory usage'
            ($recommendations -join ' ') | Should -Match 'Overall test quality'
        }
    }
}
