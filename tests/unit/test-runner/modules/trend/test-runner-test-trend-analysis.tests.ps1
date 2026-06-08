<#
tests/unit/test-runner-test-trend-analysis.tests.ps1

.SYNOPSIS
    Unit tests for TestTrendAnalysis module.
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
    Import-Module (Join-Path $modulePath 'TestTrendAnalysis.psm1') -Force -Global
}

Describe 'TestTrendAnalysis Module' {
    Context 'Get-TrendAnalysis' {
        It 'Returns placeholder trend metadata when history is unavailable' {
            $trends = Get-TrendAnalysis

            $trends.Available | Should -Be $false
            $trends.Message | Should -Match 'historical'
            $trends.Trends.Stability | Should -Be 'Unknown'
            $trends.Trends.Performance | Should -Be 'Unknown'
            $trends.Trends.Coverage | Should -Be 'Unknown'
        }
    }
}
