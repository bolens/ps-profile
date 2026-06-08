<#
tests/unit/test-runner-report-formats-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestReportFormats helpers.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestReportFormats.psm1') -Force -Global

    function script:New-MockTestResult {
        return [pscustomobject]@{
            TotalCount   = 4
            PassedCount  = 3
            FailedCount  = 1
            SkippedCount = 0
            Time         = [TimeSpan]::FromSeconds(2.5)
            PassedTests  = @(
                [pscustomobject]@{ Name = 'Passing test'; File = 'sample.tests.ps1'; Duration = [TimeSpan]::FromSeconds(0.2) }
            )
            FailedTests  = @(
                [pscustomobject]@{
                    Name        = 'Failing test'
                    File        = 'sample.tests.ps1'
                    ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                        [Exception]::new('boom'),
                        'TestFailure',
                        'NotSpecified',
                        $null
                    )
                }
            )
            SkippedTests = @()
        }
    }
}

Describe 'TestReportFormats Module' {
    Context 'New-CustomTestReport extended formats' {
        It 'Generates Markdown report output' {
            $report = New-CustomTestReport -TestResult (New-MockTestResult) -Format ([TestReportFormat]::Markdown)

            $report | Should -Match '# Test Execution Report'
            $report | Should -Match '\*\*Total Tests\*\*: 4'
            $report | Should -Match '\*\*Failed\*\*: 1'
        }

        It 'Includes detailed sections when IncludeDetails is set' {
            $report = New-CustomTestReport -TestResult (New-MockTestResult) -Format ([TestReportFormat]::JSON) -IncludeDetails
            $parsed = $report | ConvertFrom-Json

            $parsed.Details | Should -Not -BeNullOrEmpty
            @($parsed.Details.PassedTests).Count | Should -BeGreaterThan 0
            @($parsed.Details.FailedTests).Count | Should -BeGreaterThan 0
        }
    }

    Context 'ConvertTo-HtmlReport' {
        It 'Embeds recommendations when analysis data is present' {
            $reportData = @{
                GeneratedAt = '2024-01-01 00:00:00'
                Summary     = @{
                    Total    = 2
                    Passed   = 1
                    Failed   = 1
                    Skipped  = 0
                    Duration = '1.00s'
                }
                Analysis    = @{
                    Recommendations = @('Review failing tests', 'Optimize slowest test')
                }
            }

            $html = ConvertTo-HtmlReport -ReportData $reportData

            $html | Should -Match 'Recommendations'
            $html | Should -Match 'Review failing tests'
            $html | Should -Match 'Optimize slowest test'
        }
    }

    Context 'ConvertTo-MarkdownReport' {
        It 'Embeds recommendations in markdown output' {
            $reportData = @{
                GeneratedAt = '2024-01-01 00:00:00'
                Summary     = @{
                    Total    = 2
                    Passed   = 2
                    Failed   = 0
                    Skipped  = 0
                    Duration = '1.00s'
                }
                Analysis    = @{
                    Recommendations = @('Keep monitoring performance trends')
                }
            }

            $markdown = ConvertTo-MarkdownReport -ReportData $reportData

            $markdown | Should -Match '## Recommendations'
            $markdown | Should -Match 'Keep monitoring performance trends'
        }
    }
}
