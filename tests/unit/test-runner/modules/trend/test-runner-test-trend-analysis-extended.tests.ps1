<#
tests/unit/test-runner-test-trend-analysis-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestTrendAnalysis placeholder behavior.
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

Describe 'TestTrendAnalysis extended scenarios' {
    Context 'Get-TrendAnalysis' {
        It 'Reports trend analysis as unavailable without historical storage' {
            $analysis = Get-TrendAnalysis

            $analysis.Available | Should -Be $false
            $analysis.Message | Should -Match 'historical'
        }

        It 'Returns placeholder trend buckets' {
            $analysis = Get-TrendAnalysis

            $analysis.Trends.Stability | Should -Be 'Unknown'
            $analysis.Trends.Performance | Should -Be 'Unknown'
            $analysis.Trends.Coverage | Should -Be 'Unknown'
        }
    }
}
