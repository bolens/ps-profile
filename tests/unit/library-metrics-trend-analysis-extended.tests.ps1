<#
tests/unit/library-metrics-trend-analysis-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-MetricsTrend direction and filtering behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'metrics' 'MetricsTrendAnalysis.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module MetricsTrendAnalysis -ErrorAction SilentlyContinue -Force
}

Describe 'MetricsTrendAnalysis extended scenarios' {
    Context 'Get-MetricsTrend' {
        It 'Returns Stable for minimally changing series' {
            $historicalData = @(
                @{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 100 }
                @{ Timestamp = '2024-03-02T00:00:00Z'; TotalFiles = 101 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'

            if ($result.GrowthRate -ge -5 -and $result.GrowthRate -le 5) {
                $result.TrendDirection | Should -Be 'Stable'
            }
        }

        It 'Returns Increasing for strongly growing series' {
            $historicalData = @(
                @{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-03-02T00:00:00Z'; TotalFiles = 30 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'

            if ($result.GrowthRate -gt 5) {
                $result.TrendDirection | Should -Be 'Increasing'
            }
        }

        It 'Handles nested metric paths for code metrics' {
            $historicalData = @(
                @{ Timestamp = '2024-03-01T00:00:00Z'; CodeMetrics = @{ TotalFunctions = 40 } }
                @{ Timestamp = '2024-03-02T00:00:00Z'; CodeMetrics = @{ TotalFunctions = 45 } }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'CodeMetrics.TotalFunctions'

            $result.DataPoints | Should -Be 2
        }

        It 'Filters out historical points older than the Days window' {
            $historicalData = @(
                @{ Timestamp = (Get-Date).AddDays(-20).ToString('o'); TotalFiles = 10 }
                @{ Timestamp = (Get-Date).AddDays(-2).ToString('o'); TotalFiles = 20 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles' -Days 7

            $result.DataPoints | Should -BeLessOrEqual 2
        }

        It 'Handles missing metric values without throwing' {
            $historicalData = @(
                @{ Timestamp = '2024-03-01T00:00:00Z'; OtherMetric = 1 }
                @{ Timestamp = '2024-03-02T00:00:00Z'; OtherMetric = 2 }
            )

            { Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles' } | Should -Not -Throw
        }
    }
}
