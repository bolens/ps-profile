<#
tests/unit/test-runner-recommendations-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestRecommendations suggestion logic.
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
}

Describe 'TestRecommendations extended scenarios' {
    Context 'Get-TestRecommendations' {
        It 'Returns no recommendations for a clean passing analysis' {
            $analysis = [pscustomobject]@{
                Summary = [pscustomobject]@{
                    FailedTests  = 0
                    SkippedTests = 0
                    SuccessRate  = 100
                }
                FailureAnalysis = [pscustomobject]@{
                    MostCommonErrors = @()
                }
                PerformanceAnalysis = $null
            }

            @(Get-TestRecommendations -Analysis $analysis) | Should -Be @()
        }

        It 'Recommends reviewing skipped tests' {
            $analysis = [pscustomobject]@{
                Summary = [pscustomobject]@{
                    FailedTests  = 0
                    SkippedTests = 4
                    SuccessRate  = 100
                }
                FailureAnalysis = [pscustomobject]@{
                    MostCommonErrors = @()
                }
                PerformanceAnalysis = $null
            }

            $recommendations = @(Get-TestRecommendations -Analysis $analysis)

            ($recommendations -join ' ') | Should -Match 'Review 4 skipped test'
        }

        It 'Recommends improving coverage when success rate is low' {
            $analysis = [pscustomobject]@{
                Summary = [pscustomobject]@{
                    FailedTests  = 0
                    SkippedTests = 0
                    SuccessRate  = 75
                }
                FailureAnalysis = [pscustomobject]@{
                    MostCommonErrors = @()
                }
                PerformanceAnalysis = $null
            }

            $recommendations = @(Get-TestRecommendations -Analysis $analysis)

            ($recommendations -join ' ') | Should -Match 'Improve test coverage'
            ($recommendations -join ' ') | Should -Match '75%'
        }

        It 'Combines failure, performance, and skip guidance' {
            $analysis = [pscustomobject]@{
                Summary = [pscustomobject]@{
                    FailedTests  = 1
                    SkippedTests = 2
                    SuccessRate  = 80
                }
                FailureAnalysis = [pscustomobject]@{
                    MostCommonErrors = @(
                        [pscustomobject]@{
                            ErrorMessage = 'Expected true but got false'
                            Count        = 1
                        }
                    )
                }
                PerformanceAnalysis = [pscustomobject]@{
                    SlowestTests = @(
                        [pscustomobject]@{
                            Name     = 'Slow conversion test'
                            Duration = '00:00:12'
                        }
                    )
                    PerformanceDistribution = [pscustomobject]@{
                        VerySlow = 2
                    }
                }
            }

            $recommendations = @(Get-TestRecommendations -Analysis $analysis)

            @($recommendations).Count | Should -BeGreaterThan 3
            ($recommendations -join ' ') | Should -Match 'Address 1 failing test'
            ($recommendations -join ' ') | Should -Match 'Optimize slowest test'
            ($recommendations -join ' ') | Should -Match 'very slow tests'
        }
    }
}
