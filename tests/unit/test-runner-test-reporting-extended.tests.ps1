<#
tests/unit/test-runner-test-reporting-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-TestAnalysisReport assembly behavior.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestFailureAnalysis.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestPerformanceAnalysis.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestCategorization.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestRecommendations.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestTrendAnalysis.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestReporting.psm1') -Force -Global
}

Describe 'TestReporting extended scenarios' {
    Context 'Get-TestAnalysisReport' {
        It 'Leaves failure analysis empty when all tests pass' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 6
                PassedCount  = 6
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(2)
            }

            @($report.FailureAnalysis).Count | Should -Be 0
            $report.Summary.SuccessRate | Should -Be 100
        }

        It 'Records skipped tests in the summary block' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 10
                PassedCount  = 8
                FailedCount  = 0
                SkippedCount = 2
                Time         = [TimeSpan]::FromSeconds(3)
            }

            $report.Summary.SkippedTests | Should -Be 2
            ($report.Recommendations -join ' ') | Should -Match 'skipped test'
        }

        It 'Omits performance analysis unless IncludePerformance is set' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 2
                PassedCount  = 2
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(1)
                PassedTests  = @(
                    [PSCustomObject]@{ Name = 'Quick test'; Duration = [TimeSpan]::FromMilliseconds(20); File = 'quick.tests.ps1' }
                )
            }

            $report.PerformanceAnalysis | Should -BeNullOrEmpty
        }

        It 'Includes failure analysis details when tests fail' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount  = 3
                PassedCount = 1
                FailedCount = 2
                SkippedCount = 0
                Time        = [TimeSpan]::FromSeconds(4)
                FailedTests = @(
                    @{
                        Name        = 'Broken one'
                        File        = 'tests/unit/a.tests.ps1'
                        ErrorRecord = @{ Exception = @{ Message = 'boom' } }
                    },
                    @{
                        Name        = 'Broken two'
                        File        = 'tests/unit/b.tests.ps1'
                        ErrorRecord = @{ Exception = @{ Message = 'boom' } }
                    }
                )
            }

            @($report.FailureAnalysis.ByErrorMessage['boom']).Count | Should -Be 2
            ($report.Recommendations -join ' ') | Should -Match '2 failing test'
        }
    }
}
