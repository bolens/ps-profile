<#
tests/unit/test-runner-report-formats-output-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestReportFormats file output and clean summaries.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestReportFormats.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ReportFormatsOutputExtended'

    function script:New-CleanTestResult {
        return [pscustomobject]@{
            TotalCount   = 3
            PassedCount  = 3
            FailedCount  = 0
            SkippedCount = 0
            Time         = [TimeSpan]::FromSeconds(1.25)
            PassedTests  = @()
            FailedTests  = @()
            SkippedTests = @()
        }
    }
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestReportFormats output extended scenarios' {
    Context 'New-CustomTestReport' {
        It 'Writes report content to the specified OutputPath' {
            $outputPath = Join-Path $script:TempDir 'report.json'
            $null = New-CustomTestReport -TestResult (New-CleanTestResult) -Format ([TestReportFormat]::JSON) -OutputPath $outputPath

            Test-Path -LiteralPath $outputPath | Should -Be $true
            $content = Get-Content -LiteralPath $outputPath -Raw
            $content | Should -Match '"Total"\s*:\s*3'
        }

        It 'Omits Details from JSON when IncludeDetails is not set' {
            $report = New-CustomTestReport -TestResult (New-CleanTestResult) -Format ([TestReportFormat]::JSON)
            $parsed = $report | ConvertFrom-Json

            $parsed.PSObject.Properties.Name | Should -Not -Contain 'Details'
        }
    }

    Context 'ConvertTo-HtmlReport' {
        It 'Omits recommendations when analysis data is absent' {
            $reportData = @{
                GeneratedAt = '2024-01-01 00:00:00'
                Summary     = @{
                    Total    = 2
                    Passed   = 2
                    Failed   = 0
                    Skipped  = 0
                    Duration = '1.00s'
                }
            }

            $html = ConvertTo-HtmlReport -ReportData $reportData

            $html | Should -Not -Match '<h3>Recommendations</h3>'
        }
    }

    Context 'ConvertTo-MarkdownReport' {
        It 'Renders a clean all-pass summary without recommendations' {
            $reportData = @{
                GeneratedAt = '2024-01-01 00:00:00'
                Summary     = @{
                    Total    = 5
                    Passed   = 5
                    Failed   = 0
                    Skipped  = 0
                    Duration = '2.00s'
                }
            }

            $markdown = ConvertTo-MarkdownReport -ReportData $reportData

            $markdown | Should -Match '\*\*Passed\*\*: 5'
            $markdown | Should -Not -Match '## Recommendations'
        }
    }
}
