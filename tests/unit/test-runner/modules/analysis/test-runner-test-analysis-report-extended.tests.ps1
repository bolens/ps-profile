<#
tests/unit/test-runner-test-analysis-report-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-TestAnalysisReport orchestration.
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
    Import-Module (Join-Path $modulePath 'TestFailureAnalysis.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestPerformanceAnalysis.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestCategorization.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestRecommendations.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestTrendAnalysis.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestReporting.psm1') -Force -Global
}

Describe 'Get-TestAnalysisReport extended scenarios' {
    Context 'Summary assembly' {
        It 'Calculates success rate for mixed pass and fail counts' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 4
                PassedCount  = 3
                FailedCount  = 1
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(2)
            }

            $report.Summary.SuccessRate | Should -Be 75
            $report.Summary.TotalTests | Should -Be 4
        }

        It 'Leaves performance analysis null unless explicitly requested' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 1
                PassedCount  = 1
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(1)
                PassedTests  = @(
                    [PSCustomObject]@{ Name = 'Quick'; Duration = [TimeSpan]::FromMilliseconds(10); File = 'quick.tests.ps1' }
                )
            }

            $report.PerformanceAnalysis | Should -BeNullOrEmpty
        }
    }

    Context 'Failure and recommendation sections' {
        It 'Includes failure analysis when failures are present' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 1
                PassedCount  = 0
                FailedCount  = 1
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(1)
                FailedTests  = @(
                    @{
                        Name        = 'Broken test'
                        File        = 'tests/unit/broken.tests.ps1'
                        Tags        = @('Unit')
                        ErrorRecord = @{ Exception = @{ Message = 'assertion failed' } }
                    }
                )
            }

            @($report.FailureAnalysis).Count | Should -BeGreaterThan 0
            $report.Recommendations | Should -Not -BeNullOrEmpty
        }

        It 'Omits failure analysis for all-pass result sets' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 2
                PassedCount  = 2
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(1)
            }

            $report.FailureAnalysis | Should -Be @()
        }
    }

    Context 'Optional analysis sections' {
        It 'Includes slowest tests when performance analysis is enabled' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 2
                PassedCount  = 2
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(3)
                PassedTests  = @(
                    [PSCustomObject]@{ Name = 'Slow test'; Duration = [TimeSpan]::FromSeconds(2); File = 'slow.tests.ps1' }
                    [PSCustomObject]@{ Name = 'Fast test'; Duration = [TimeSpan]::FromMilliseconds(50); File = 'fast.tests.ps1' }
                )
            } -IncludePerformance

            $report.PerformanceAnalysis.SlowestTests[0].Name | Should -Be 'Slow test'
        }

        It 'Attaches skipped counts in the summary block' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 3
                PassedCount  = 1
                FailedCount  = 0
                SkippedCount = 2
                Time         = [TimeSpan]::FromSeconds(1)
            }

            $report.Summary.SkippedTests | Should -Be 2
        }
    }
}
