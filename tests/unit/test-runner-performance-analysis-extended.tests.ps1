<#
tests/unit/test-runner-performance-analysis-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-PerformanceAnalysis distribution and ranking.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestPerformanceAnalysis.psm1') -Force -Global

    function script:New-PassedTest {
        param(
            [string]$Name,
            [double]$Seconds
        )

        return [pscustomobject]@{
            Name     = $Name
            Duration = [TimeSpan]::FromSeconds($Seconds)
            File     = "tests/unit/$Name.tests.ps1"
        }
    }
}

Describe 'TestPerformanceAnalysis extended scenarios' {
    Context 'Get-PerformanceAnalysis' {
        It 'Returns empty analysis details when no passed tests exist' {
            $result = @{
                Time         = [TimeSpan]::FromSeconds(0)
                PassedTests  = @()
            }

            $analysis = Get-PerformanceAnalysis -TestResult $result

            $analysis.AverageDuration | Should -BeNullOrEmpty
            @($analysis.SlowestTests).Count | Should -Be 0
            @($analysis.FastestTests).Count | Should -Be 0
        }

        It 'Buckets tests into performance distribution categories' {
            $result = @{
                Time        = [TimeSpan]::FromSeconds(12)
                PassedTests = @(
                    (New-PassedTest -Name 'fast' -Seconds 0.05)
                    (New-PassedTest -Name 'medium' -Seconds 0.5)
                    (New-PassedTest -Name 'slow' -Seconds 2)
                    (New-PassedTest -Name 'very-slow' -Seconds 12)
                )
            }

            $analysis = Get-PerformanceAnalysis -TestResult $result

            $analysis.PerformanceDistribution.Fast | Should -Be 1
            $analysis.PerformanceDistribution.Medium | Should -Be 1
            $analysis.PerformanceDistribution.Slow | Should -Be 1
            $analysis.PerformanceDistribution.VerySlow | Should -Be 1
        }

        It 'Identifies slowest and fastest passed tests' {
            $result = @{
                Time        = [TimeSpan]::FromSeconds(6)
                PassedTests = @(
                    (New-PassedTest -Name 'alpha' -Seconds 1)
                    (New-PassedTest -Name 'beta' -Seconds 5)
                    (New-PassedTest -Name 'gamma' -Seconds 0.2)
                )
            }

            $analysis = Get-PerformanceAnalysis -TestResult $result

            $analysis.SlowestTests[0].Name | Should -Be 'beta'
            $analysis.FastestTests[0].Name | Should -Be 'gamma'
        }

        It 'Computes average duration across passed tests' {
            $result = @{
                Time        = [TimeSpan]::FromSeconds(4)
                PassedTests = @(
                    (New-PassedTest -Name 'one' -Seconds 1)
                    (New-PassedTest -Name 'two' -Seconds 3)
                )
            }

            $analysis = Get-PerformanceAnalysis -TestResult $result

            $analysis.AverageDuration.TotalSeconds | Should -Be 2
        }

        It 'Preserves total duration from the test result' {
            $duration = [TimeSpan]::FromSeconds(42)
            $result = @{
                Time        = $duration
                PassedTests = @((New-PassedTest -Name 'only' -Seconds 1))
            }

            (Get-PerformanceAnalysis -TestResult $result).TotalDuration | Should -Be $duration
        }
    }
}
