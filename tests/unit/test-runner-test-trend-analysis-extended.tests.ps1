<#
tests/unit/test-runner-test-trend-analysis-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestTrendAnalysis placeholder behavior.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
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
