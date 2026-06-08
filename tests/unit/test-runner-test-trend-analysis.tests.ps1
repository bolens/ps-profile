<#
tests/unit/test-runner-test-trend-analysis.tests.ps1

.SYNOPSIS
    Unit tests for TestTrendAnalysis module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
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
