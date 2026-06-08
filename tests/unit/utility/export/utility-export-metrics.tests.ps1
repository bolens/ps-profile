<#
tests/unit/utility-export-metrics.tests.ps1

.SYNOPSIS
    Behavioral unit tests for export-metrics.ps1 execution.
#>

function global:Invoke-ExportMetricsScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:ExportMetricsScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ExportMetricsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'export-metrics.ps1'
    $ConfirmPreference = 'None'
}

Describe 'export-metrics.ps1 execution' {
    It 'Exports metrics to a custom output path without enum load errors' {
        $outputPath = Join-Path (New-TestTempDirectory -Prefix 'ExportMetricsOut') 'metrics.json'
        try {
            $result = Invoke-ExportMetricsScript -ArgumentList @('-OutputPath', $outputPath)

            $result.Output | Should -Not -Match 'Unable to find type \[OutputFormat\]'
            $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
            if ($result.ExitCode -eq 0) {
                Test-Path -LiteralPath $outputPath | Should -BeTrue
            }
        }
        finally {
            $parent = Split-Path -Parent $outputPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Rejects unsupported OutputFormat values' {
        $result = Invoke-ExportMetricsScript -ArgumentList @('-OutputFormat', 'Xml')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'OutputFormat|ValidateSet|cannot be validated'
    }

    It 'Exports metrics to CSV at a custom output path' {
        $outputPath = Join-Path (New-TestTempDirectory -Prefix 'ExportMetricsCsv') 'metrics.csv'
        try {
            $result = Invoke-ExportMetricsScript -ArgumentList @(
                '-OutputFormat', 'Csv',
                '-OutputPath', $outputPath,
                '-IncludeCodeMetrics'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Metrics exported to'
            Test-Path -LiteralPath $outputPath | Should -BeTrue
            if ((Get-Item -LiteralPath $outputPath).Length -gt 0) {
                (Get-Content -LiteralPath $outputPath -Raw) | Should -Match 'MetricType|TotalFiles|,'
            }
        }
        finally {
            $parent = Split-Path -Parent $outputPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Exports metrics as a human-readable table to stdout' {
        $result = Invoke-ExportMetricsScript -ArgumentList @(
            '-OutputFormat', 'Table',
            '-IncludeCodeMetrics:False'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Exporting metrics|MetricType|Timestamp|Code Metrics'
    }
}
