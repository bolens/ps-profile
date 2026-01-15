<#
scripts/utils/code-quality/modules/TestReportFormats.psm1

.SYNOPSIS
    Test report formatting utilities for the PowerShell profile test runner.

.DESCRIPTION
    Provides functions for generating test reports in various formats including
    HTML, Markdown, and JSON.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe configuration values.
#>

# Import CommonEnums for TestReportFormat enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Locale module for locale-aware date formatting
$localeModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Locale.psm1'
if ($localeModulePath -and -not [string]::IsNullOrWhiteSpace($localeModulePath) -and (Test-Path -LiteralPath $localeModulePath)) {
    Import-Module $localeModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Generates a custom test report in various formats.

.DESCRIPTION
    Creates detailed test reports in JSON, HTML, or Markdown format
    with customizable content and styling.

.PARAMETER TestResult
    The Pester test result object.

.PARAMETER Analysis
    Optional test analysis data.

.PARAMETER Format
    Report format: JSON, HTML, or Markdown.

.PARAMETER OutputPath
    Path to save the report file.

.PARAMETER IncludeDetails
    Include detailed test information in the report.

.OUTPUTS
    Report content as string
#>
function New-CustomTestReport {
    param(
        [Parameter(Mandatory)]
        $TestResult,

        $Analysis,

        [TestReportFormat]$Format = [TestReportFormat]::JSON,

        [string]$OutputPath,

        [switch]$IncludeDetails
    )

    # Use locale-aware date formatting for user-facing report
    $generatedAt = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
        Format-LocaleDate (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
    }
    else {
        (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }
    
    # Format duration using locale-aware formatting
    $durationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        Format-LocaleNumber ([Math]::Round($TestResult.Time.TotalSeconds, 2)) -Format 'N2'
    }
    else {
        [Math]::Round($TestResult.Time.TotalSeconds, 2).ToString("N2")
    }
    
    $reportData = @{
        GeneratedAt = $generatedAt
        Summary     = @{
            Total    = $TestResult.TotalCount
            Passed   = $TestResult.PassedCount
            Failed   = $TestResult.FailedCount
            Skipped  = $TestResult.SkippedCount
            Duration = "${durationStr}s"
        }
        Analysis    = $Analysis
    }

    if ($IncludeDetails) {
        $reportData.Details = @{
            PassedTests  = $TestResult.PassedTests | Select-Object Name, File, Duration
            FailedTests  = $TestResult.FailedTests | Select-Object Name, File, ErrorRecord
            SkippedTests = $TestResult.SkippedTests | Select-Object Name, File
        }
    }

    # Convert enum to string
    $formatString = $Format.ToString()
    
    $content = switch ($formatString) {
        'JSON' {
            $reportData | ConvertTo-Json -Depth 10
        }
        'HTML' {
            ConvertTo-HtmlReport -ReportData $reportData
        }
        'Markdown' {
            ConvertTo-MarkdownReport -ReportData $reportData
        }
    }

    if ($OutputPath) {
        $content | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-ScriptMessage -Message "Test report saved to: $OutputPath"
    }

    return $content
}

<#
.SYNOPSIS
    Converts report data to HTML format.

.DESCRIPTION
    Generates an HTML report with styling and interactive elements.

.PARAMETER ReportData
    The report data object.

.OUTPUTS
    HTML content as string
#>
function ConvertTo-HtmlReport {
    param(
        [Parameter(Mandatory)]
        $ReportData
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Execution Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .passed { color: green; }
        .failed { color: red; }
        .skipped { color: orange; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .recommendations { background: #fff3cd; padding: 10px; border-left: 4px solid #ffc107; }
    </style>
</head>
<body>
    <h1>Test Execution Report</h1>
    <p>Generated at: $($ReportData.GeneratedAt)</p>

    <div class="summary">
        <h2>Summary</h2>
        <p>Total Tests: $($ReportData.Summary.Total)</p>
        <p class="passed">Passed: $($ReportData.Summary.Passed)</p>
        <p class="failed">Failed: $($ReportData.Summary.Failed)</p>
        <p class="skipped">Skipped: $($ReportData.Summary.Skipped)</p>
        <p>Duration: $($ReportData.Summary.Duration)</p>
    </div>

"@

    if ($ReportData.Analysis.Recommendations) {
        $recommendationsList = $ReportData.Analysis.Recommendations | ForEach-Object { "<li>$_</li>" }
        $html += @"

    <div class="recommendations">
        <h3>Recommendations</h3>
        <ul>
            $([string]::Join('', $recommendationsList))
        </ul>
    </div>
"@
    }

    $html += @"

</body>
</html>
"@

    return $html
}

<#
.SYNOPSIS
    Converts report data to Markdown format.

.DESCRIPTION
    Generates a Markdown report suitable for documentation or GitHub.

.PARAMETER ReportData
    The report data object.

.OUTPUTS
    Markdown content as string
#>
function ConvertTo-MarkdownReport {
    param(
        [Parameter(Mandatory)]
        $ReportData
    )

    $markdown = @"
# Test Execution Report

Generated at: $($ReportData.GeneratedAt)

## Summary

- **Total Tests**: $($ReportData.Summary.Total)
- **Passed**: $($ReportData.Summary.Passed)
- **Failed**: $($ReportData.Summary.Failed)
- **Skipped**: $($ReportData.Summary.Skipped)
- **Duration**: $($ReportData.Summary.Duration)

"@

    if ($ReportData.Analysis.Recommendations) {
        $recommendationsList = $ReportData.Analysis.Recommendations | ForEach-Object { "- $_" }
        $markdown += @"

## Recommendations

$([string]::Join("`n", $recommendationsList))

"@
    }

    return $markdown
}

Export-ModuleMember -Function @(
    'New-CustomTestReport',
    'ConvertTo-HtmlReport',
    'ConvertTo-MarkdownReport'
)

