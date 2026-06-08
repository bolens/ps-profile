<#
tests/unit/library-metrics-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for metrics trend and snapshot edge cases.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'metrics' 'MetricsTrendAnalysis.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $libPath 'metrics' 'MetricsHistory.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $libPath 'metrics' 'MetricsSnapshot.psm1') -DisableNameChecking -ErrorAction Stop

    $script:TempDir = New-TestTempDirectory -Prefix 'MetricsExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Metrics extended scenarios' {
    Context 'Get-MetricsTrend' {
        It 'Detects declining trends when values decrease over time' {
            $historicalData = @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 30 }
                @{ Timestamp = '2024-01-02T00:00:00Z'; TotalFiles = 20 }
                @{ Timestamp = '2024-01-03T00:00:00Z'; TotalFiles = 10 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result.TrendDirection | Should -Be 'Decreasing'
            $result.GrowthRate | Should -BeLessThan 0
        }

        It 'Reports insufficient data for a single observation' {
            $result = Get-MetricsTrend -HistoricalData @(
                @{ Timestamp = '2024-01-01T00:00:00Z'; TotalFiles = 10 }
            ) -MetricName 'TotalFiles'

            $result.TrendDirection | Should -Be 'InsufficientData'
            $result.DataPoints | Should -Be 1
        }

        It 'Handles missing metric keys without throwing' {
            $result = Get-MetricsTrend -HistoricalData @(
                @{ Timestamp = '2024-01-01T00:00:00Z' }
                @{ Timestamp = '2024-01-02T00:00:00Z' }
            ) -MetricName 'MissingMetric'

            $result | Should -Not -BeNullOrEmpty
            $result.TrendDirection | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-HistoricalMetrics' {
        It 'Ignores non-JSON files in the history directory' {
            $historyDir = Join-Path $script:TempDir 'mixed-history'
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $historyDir 'notes.txt') -Value 'not metrics' -Encoding UTF8
            @{
                Timestamp  = '2024-01-01T00:00:00Z'
                TotalFiles = 7
            } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $historyDir 'metrics-20240101-000000.json') -Encoding UTF8

            $result = Get-HistoricalMetrics -HistoryPath $historyDir
            $result.Count | Should -Be 1
            $result[0].TotalFiles | Should -Be 7
        }
    }

    Context 'Save-MetricsSnapshot' {
        It 'Creates the output directory when it does not exist' {
            $snapshotDir = Join-Path $script:TempDir 'new-snapshot-dir'
            $snapshotPath = Save-MetricsSnapshot -OutputPath $snapshotDir

            Test-Path -LiteralPath $snapshotDir | Should -Be $true
            Test-Path -LiteralPath $snapshotPath | Should -Be $true
        }
    }
}
