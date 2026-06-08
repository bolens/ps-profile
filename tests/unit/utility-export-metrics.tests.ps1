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
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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
}
