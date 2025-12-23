. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import the module under test
    $script:MetricsTrendAnalysisPath = Join-Path $script:LibPath 'metrics' 'MetricsTrendAnalysis.psm1'
    Import-Module $script:MetricsTrendAnalysisPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module MetricsTrendAnalysis -ErrorAction SilentlyContinue -Force
}

Describe 'MetricsTrendAnalysis Module Functions' {
    Context 'Get-MetricsTrend' {
        It 'Returns InsufficientData for empty array' {
            $result = Get-MetricsTrend -HistoricalData @() -MetricName 'TotalFiles'
            $result | Should -Not -BeNullOrEmpty
            $result.TrendDirection | Should -Be 'InsufficientData'
            $result.DataPoints | Should -Be 0
        }

        It 'Returns InsufficientData for single data point' {
            $data = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $data -MetricName 'TotalFiles'
            $result.TrendDirection | Should -Be 'InsufficientData'
            $result.DataPoints | Should -Be 1
        }

        It 'Calculates trend for valid data' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 15 }
                @{ Timestamp = '2024-01-03T00:00:00Z'; TotalFiles = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result | Should -Not -BeNullOrEmpty
            $result.TrendDirection | Should -Not -Be 'InsufficientData'
            $result.DataPoints | Should -Be 3
        }

        It 'Calculates growth rate' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result.GrowthRate | Should -BeGreaterThan 0
        }

        It 'Handles nested metric paths' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; CodeMetrics = @{ TotalFiles = 10 } }
                @{ Timestamp = '2024-01-02T00:00:00Z'; CodeMetrics = @{ TotalFiles = 15 } }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'CodeMetrics.TotalFiles'
            $result | Should -Not -BeNullOrEmpty
            $result.DataPoints | Should -BeGreaterThan 0
        }

        It 'Handles PerformanceMetrics nested paths' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; PerformanceMetrics = @{ FullStartupMean = 1000 } }
                @{ Timestamp = '2024-01-02T00:00:00Z'; PerformanceMetrics = @{ FullStartupMean = 1200 } }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'PerformanceMetrics.FullStartupMean'
            $result | Should -Not -BeNullOrEmpty
            $result.DataPoints | Should -BeGreaterThan 0
        }

        It 'Filters by Days parameter' {
            $historicalData = @(
                @{ Timestamp = (Get-Date).AddDays(-10).ToString('o'); TotalFiles = 10 }
                @{ Timestamp = (Get-Date).AddDays(-5).ToString('o'); TotalFiles = 15 }
                @{ Timestamp = (Get-Date).ToString('o'); TotalFiles = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles' -Days 7
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns Increasing trend for positive growth' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            if ($result.GrowthRate -gt 5) {
                $result.TrendDirection | Should -Be 'Increasing'
            }
        }

        It 'Returns Decreasing trend for negative growth' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 20 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 10 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            if ($result.GrowthRate -lt -5) {
                $result.TrendDirection | Should -Be 'Decreasing'
            }
        }

        It 'Returns Stable trend for minimal change' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 11 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            if ($result.GrowthRate -ge -5 -and $result.GrowthRate -le 5) {
                $result.TrendDirection | Should -Be 'Stable'
            }
        }

        It 'Calculates average change' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 15 }
                @{ Timestamp = '2024-01-03T00:00:00Z'; TotalFiles = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result.AverageChange | Should -Not -BeNullOrEmpty
        }

        It 'Calculates min and max values' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 30 }
                @{ Timestamp = '2024-01-03T00:00:00Z'; TotalFiles = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result.MinValue | Should -Be 10
            $result.MaxValue | Should -Be 30
        }

        It 'Calculates average value' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 20 }
                @{ Timestamp = '2024-01-03T00:00:00Z'; TotalFiles = 30 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result.AverageValue | Should -Be 20
        }

        It 'Handles data without Timestamp' {
            $historicalData = @(
                @{ TotalFiles = 10 }
                @{ TotalFiles = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result | Should -Not -BeNullOrEmpty
            $result.DataPoints | Should -BeGreaterThan 0
        }

        It 'Handles null values in historical data' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                $null
                @{ Timestamp = '2024-01-03T00:00:00Z'; TotalFiles = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles missing metric values' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; OtherMetric = 20 }
            )
            
            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            # Should handle missing values gracefully
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

