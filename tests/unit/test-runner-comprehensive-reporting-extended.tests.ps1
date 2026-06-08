<#
tests/unit/test-runner-comprehensive-reporting-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestComprehensiveReporting module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/CommonEnums.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestComprehensiveReporting.psm1') -Force -Global

    function script:New-PassingTestResult {
        param(
            [int]$Total = 50
        )

        return [pscustomobject]@{
            TotalCount   = $Total
            PassedCount  = $Total
            FailedCount  = 0
            SkippedCount = 0
            Time         = [TimeSpan]::FromSeconds(8)
            FailedTests  = @()
        }
    }
}

Describe 'TestComprehensiveReporting extended scenarios' {
    Context 'New-ComprehensiveTestReport' {
        It 'Computes quality metrics without performance data' {
            $report = New-ComprehensiveTestReport -TestResult (New-PassingTestResult)

            $report.ReportType | Should -Be 'Summary'
            $report.Performance.Count | Should -Be 0
            $report.QualityMetrics.TestCoverage | Should -Be 100
            $report.QualityMetrics.StabilityScore | Should -Be 100
            $report.QualityMetrics.OverallQuality | Should -BeGreaterThan 0
        }

        It 'Uses Detailed report type when requested' {
            $report = New-ComprehensiveTestReport -TestResult (New-PassingTestResult) -ReportType ([ReportFormat]::Detailed)

            $report.ReportType | Should -Be 'Detailed'
        }

        It 'Produces no actionable recommendations for healthy all-passing suites' {
            $report = New-ComprehensiveTestReport -TestResult (New-PassingTestResult)

            $report.Trends.Count | Should -Be 0
            @(
                @($report.Recommendations) |
                    Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) }
            ).Count | Should -Be 0
        }

        It 'Recommends quality improvements for smaller suites with low coverage score' {
            $report = New-ComprehensiveTestReport -TestResult (New-PassingTestResult -Total 20)

            @($report.Recommendations).Count | Should -BeGreaterThan 0
            ($report.Recommendations -join ' ') | Should -Match 'Overall test quality'
        }

        It 'Includes historical trend data when provided' {
            $historical = @(
                @{ FailedCount = 0; TotalCount = 20; Time = [TimeSpan]::FromSeconds(6) },
                @{ FailedCount = 1; TotalCount = 20; Time = [TimeSpan]::FromSeconds(7) }
            )

            $report = New-ComprehensiveTestReport -TestResult (New-PassingTestResult) -HistoricalData $historical

            $report.Trends.RecentRuns | Should -Be 1
            $report.Trends.AverageFailureRate | Should -Be 0
        }
    }
}
