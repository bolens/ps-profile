<#
tests/unit/test-runner-test-analysis-report.tests.ps1

.SYNOPSIS
    Unit tests for Get-TestAnalysisReport orchestration.
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

Describe 'Get-TestAnalysisReport' {
    Context 'Report assembly' {
        It 'Returns zero success rate for empty result sets' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 0
                PassedCount  = 0
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::Zero
            }

            $report.Summary.SuccessRate | Should -Be 0
            $report.FailureAnalysis | Should -Be @()
        }

        It 'Includes performance analysis when requested' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 2
                PassedCount  = 2
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(1)
                PassedTests  = @(
                    [PSCustomObject]@{ Name = 'Quick test'; Duration = [TimeSpan]::FromMilliseconds(20); File = 'quick.tests.ps1' }
                )
            } -IncludePerformance

            $report.PerformanceAnalysis | Should -Not -BeNullOrEmpty
            $report.PerformanceAnalysis.FastestTests[0].Name | Should -Be 'Quick test'
        }

        It 'Attaches trend placeholder when IncludeTrends is set' {
            $report = Get-TestAnalysisReport -TestResult @{
                TotalCount   = 1
                PassedCount  = 1
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(1)
            } -IncludeTrends

            $report.TrendAnalysis.Available | Should -Be $false
            $report.TrendAnalysis.Message | Should -Match 'historical'
        }
    }
}
