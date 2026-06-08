<#
tests/unit/utility-migrate-metrics-to-sqlite.tests.ps1

.SYNOPSIS
    Behavioral unit tests for migrate-metrics-to-sqlite.ps1 setup validation.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:MigrateMetricsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'migrate-metrics-to-sqlite.ps1'
    $ConfirmPreference = 'None'
}

Describe 'migrate-metrics-to-sqlite.ps1 execution' {
    It 'Reports setup error when PerformanceMetricsDatabase module is unavailable' {
        $result = Invoke-TestScriptFile -ScriptPath $script:MigrateMetricsScript

        $result.ExitCode | Should -BeIn @(1, 2, 3)
        $result.Output | Should -Match 'Performance Metrics Database|PerformanceMetricsDatabase|not found'
    }

    It 'Reports setup error before importing when the database module is unavailable' {
        $baselinePath = Join-Path (New-TestTempDirectory -Prefix 'MigrateBaseline') 'baseline.json'
        @{
            FullStartupMean = 120.5
            Timestamp       = '2026-01-01T00:00:00Z'
        } | ConvertTo-Json | Set-Content -LiteralPath $baselinePath -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:MigrateMetricsScript -ArgumentList @(
                '-BaselineFile', $baselinePath
            )

            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'Performance Metrics Database|PerformanceMetricsDatabase|not found'
            $result.Output | Should -Not -Match 'Imported [1-9]'
        }
        finally {
            $parent = Split-Path -Parent $baselinePath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
