. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Metrics Module Functions' {
    BeforeAll {
        # Import the Metrics modules (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'metrics' 'MetricsTrendAnalysis.psm1') -DisableNameChecking -ErrorAction Stop
        Import-Module (Join-Path $libPath 'metrics' 'MetricsHistory.psm1') -DisableNameChecking -ErrorAction Stop
        Import-Module (Join-Path $libPath 'metrics' 'MetricsSnapshot.psm1') -DisableNameChecking -ErrorAction Stop
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:TestTempDir = New-TestTempDirectory -Prefix 'MetricsTests'
    }

    AfterAll {
        if ($script:TestTempDir -and (Test-Path $script:TestTempDir)) {
            Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-MetricsTrend' {
        It 'Handles insufficient data gracefully' {
            $emptyData = @()
            $result = Get-MetricsTrend -HistoricalData $emptyData -MetricName 'TotalFiles'
            $result.TrendDirection | Should -Be 'InsufficientData'
            $result.DataPoints | Should -Be 0
            $result.Message | Should -Match 'Need at least 2 data points'
        }

        It 'Calculates trend for valid data' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 15 }
                @{ Timestamp = '2024-01-03T00:00:00Z'; TotalFiles = 20 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result.TrendDirection | Should -Not -Be 'InsufficientData'
            $result.DataPoints | Should -Be 3
            $result.GrowthRate | Should -BeGreaterThan 0
        }

        It 'Handles nested metric paths' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; CodeMetrics = @{ TotalFiles = 10 } }
                @{ Timestamp = '2024-01-02T00:00:00Z'; CodeMetrics = @{ TotalFiles = 15 } }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'CodeMetrics.TotalFiles'
            $result.DataPoints | Should -BeGreaterThan 0
        }
    }

    Context 'Get-HistoricalMetrics' {
        It 'Returns empty array for non-existent directory' {
            $nonExistentPath = Join-Path $script:TestTempDir 'nonexistent-history'
            $result = Get-HistoricalMetrics -HistoryPath $nonExistentPath
            $result | Should -BeNullOrEmpty
        }

        It 'Loads historical metrics from JSON files' {
            $historyDir = Join-Path $script:TestTempDir 'history'
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null

            $metrics = @{
                Timestamp  = '2024-01-01T00:00:00Z'
                TotalFiles = 10
            } | ConvertTo-Json

            $metricsFile = Join-Path $historyDir 'metrics-20240101-000000.json'
            $metrics | Set-Content -Path $metricsFile -Encoding UTF8

            $result = Get-HistoricalMetrics -HistoryPath $historyDir
            $result.Count | Should -BeGreaterThan 0
            $result[0].TotalFiles | Should -Be 10
        }

        It 'Respects Limit parameter' {
            $historyDir = Join-Path $script:TestTempDir 'history-limit'
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null

            1..5 | ForEach-Object {
                $metrics = @{
                    Timestamp  = "2024-01-0$_`T00:00:00Z"
                    TotalFiles = $_
                } | ConvertTo-Json

                $metricsFile = Join-Path $historyDir "metrics-2024010$_`-000000.json"
                $metrics | Set-Content -Path $metricsFile -Encoding UTF8
            }

            $result = Get-HistoricalMetrics -HistoryPath $historyDir -Limit 3
            $result.Count | Should -BeLessOrEqual 3
        }
    }

    Context 'Save-MetricsSnapshot' {
        It 'Saves metrics snapshot to specified path' {
            $snapshotDir = Join-Path $script:TestTempDir 'snapshots'
            $snapshotPath = Save-MetricsSnapshot -OutputPath $snapshotDir
            Test-Path $snapshotPath | Should -Be $true
            $snapshotPath | Should -Match 'metrics-\d{8}-\d{6}\.json'

            $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
            $snapshotContent.Timestamp | Should -Not -BeNullOrEmpty
        }

        It 'Includes code metrics when specified' {
            $snapshotDir = Join-Path $script:TestTempDir 'snapshots-code'
            $codeMetricsFile = Join-Path $script:RepoRoot 'scripts' 'data' 'code-metrics.json'

            if (Test-Path $codeMetricsFile) {
                $snapshotPath = Save-MetricsSnapshot -OutputPath $snapshotDir -IncludeCodeMetrics
                $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
                $snapshotContent.CodeMetrics | Should -Not -BeNullOrEmpty
            }
            else {
                Set-ItResult -Skipped -Because "code-metrics.json not found"
            }
        }
    }
}
