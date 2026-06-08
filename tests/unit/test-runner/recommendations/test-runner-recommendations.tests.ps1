<#
tests/unit/test-runner-recommendations.tests.ps1

.SYNOPSIS
    Unit tests for TestRecommendations and TestAnalysis modules.
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
    Import-Module (Join-Path $modulePath 'TestRecommendations.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestAnalysis.psm1') -Force -Global
}

Describe 'TestRecommendations Module' {
    Context 'Get-TestRecommendations' {
        It 'Suggests addressing failures and common errors' {
            $analysis = [pscustomobject]@{
                Summary = [pscustomobject]@{
                    FailedTests  = 2
                    SkippedTests = 0
                    SuccessRate  = 95
                }
                FailureAnalysis = [pscustomobject]@{
                    MostCommonErrors = @(
                        [pscustomobject]@{
                            ErrorMessage = 'Connection refused'
                            Count        = 2
                        }
                    )
                }
                PerformanceAnalysis = $null
            }

            $recommendations = Get-TestRecommendations -Analysis $analysis

            $recommendations | Should -Contain 'Address 2 failing test(s)'
            ($recommendations -join ' ') | Should -Match 'Connection refused'
        }

        It 'Suggests performance optimizations for slow tests' {
            $analysis = [pscustomobject]@{
                Summary = [pscustomobject]@{
                    FailedTests  = 0
                    SkippedTests = 0
                    SuccessRate  = 100
                }
                FailureAnalysis = [pscustomobject]@{
                    MostCommonErrors = @()
                }
                PerformanceAnalysis = [pscustomobject]@{
                    SlowestTests = @(
                        [pscustomobject]@{
                            Name     = 'Heavy integration test'
                            Duration = '00:00:15'
                        }
                    )
                    PerformanceDistribution = [pscustomobject]@{
                        VerySlow = 3
                    }
                }
            }

            $recommendations = Get-TestRecommendations -Analysis $analysis

            ($recommendations -join ' ') | Should -Match 'Heavy integration test'
            ($recommendations -join ' ') | Should -Match 'very slow tests'
        }

        It 'Suggests coverage and skip review when applicable' {
            $analysis = [pscustomobject]@{
                Summary = [pscustomobject]@{
                    FailedTests  = 0
                    SkippedTests = 4
                    SuccessRate  = 80
                }
                FailureAnalysis = [pscustomobject]@{
                    MostCommonErrors = @()
                }
                PerformanceAnalysis = $null
            }

            $recommendations = Get-TestRecommendations -Analysis $analysis

            ($recommendations -join ' ') | Should -Match 'Improve test coverage'
            ($recommendations -join ' ') | Should -Match '4 skipped test'
        }
    }
}

Describe 'TestAnalysis Module' {
    Context 'Analyze-TestTrends' {
        It 'Computes average failure rate from current result' {
            $current = [pscustomobject]@{
                TotalCount  = 10
                FailedCount = 2
                Time        = [TimeSpan]::FromSeconds(4)
            }

            $trends = Analyze-TestTrends -CurrentResult $current -HistoricalData @()

            $trends.AverageFailureRate | Should -Be 0.2
            $trends.AverageDuration | Should -Be $current.Time
            $trends.RecentRuns | Should -Be 1
        }
    }

    Context 'Get-ComprehensiveRecommendations' {
        It 'Returns quality and performance recommendations from report data' {
            $report = [pscustomobject]@{
                TestResults = [pscustomobject]@{
                    SuccessRate = 75
                    FailedTests = 8
                }
                Performance = [pscustomobject]@{
                    PerformanceGrade = 'F'
                    MemoryUsage      = [pscustomobject]@{
                        PeakMB = 1500
                    }
                }
                QualityMetrics = [pscustomobject]@{
                    OverallQuality = 55
                }
            }

            $recommendations = Get-ComprehensiveRecommendations -Report $report

            ($recommendations -join ' ') | Should -Match 'Improve test success rate'
            ($recommendations -join ' ') | Should -Match '8 failing tests'
            ($recommendations -join ' ') | Should -Match 'Critical performance issues'
            ($recommendations -join ' ') | Should -Match 'High memory usage'
            ($recommendations -join ' ') | Should -Match 'Overall test quality'
        }
    }
}
