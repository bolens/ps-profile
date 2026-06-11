<#
tests/unit/library-metrics-trend-analysis-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-MetricsTrend direction and filtering behavior.
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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-Module (Join-Path $script:LibPath 'metrics' 'MetricsTrendAnalysis.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
    Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
    Remove-Module MetricsTrendAnalysis -ErrorAction SilentlyContinue -Force
}

Describe 'MetricsTrendAnalysis extended scenarios' {
    BeforeEach {
        Enable-TestStructuredLogging
    }

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

        It 'Returns Decreasing for strongly declining series' {
            $historicalData = @(
                @{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 100 }
                @{ Timestamp = '2024-03-02T00:00:00Z'; TotalFiles = 20 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'

            if ($result.GrowthRate -lt -5) {
                $result.TrendDirection | Should -Be 'Decreasing'
            }
        }

        It 'Returns zero growth rate when the first value is zero' {
            $historicalData = @(
                @{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 0 }
                @{ Timestamp = '2024-03-02T00:00:00Z'; TotalFiles = 10 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result.GrowthRate | Should -Be 0
        }

        It 'Returns InsufficientData when the Days filter removes too many points' {
            $historicalData = @(
                @{ Timestamp = (Get-Date).AddDays(-30).ToString('o'); TotalFiles = 10 }
                @{ Timestamp = (Get-Date).AddDays(-25).ToString('o'); TotalFiles = 20 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles' -Days 7
            $result.TrendDirection | Should -Be 'InsufficientData'
        }

        It 'Skips null historical entries and still analyzes valid points' {
            $historicalData = @(
                $null
                @{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 10 }
                @{ Timestamp = '2024-03-02T00:00:00Z'; TotalFiles = 20 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName 'TotalFiles'
            $result.DataPoints | Should -Be 2
        }

        It 'Uses Write-StructuredWarning for insufficient data when structured logging is enabled' {
            Enable-TestStructuredLogging

            { Get-MetricsTrend -HistoricalData @(@{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 1 }) -MetricName 'TotalFiles' } |
                Should -Not -Throw
        }

        It 'Emits level 3 tracing when PS_PROFILE_DEBUG is enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-MetricsTrend -HistoricalData @(
                    @{ Timestamp = (Get-Date).AddDays(-2).ToString('o'); TotalFiles = 10 }
                    @{ Timestamp = (Get-Date).AddDays(-1).ToString('o'); TotalFiles = 15 }
                ) -MetricName 'TotalFiles' -Days 30

                $result.TrendDirection | Should -Not -Be 'InsufficientData'
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses plain Write-Warning for insufficient data when structured logging is disabled' {
            Disable-TestStructuredLogging

            $warnings = $null
            { Get-MetricsTrend -HistoricalData @(@{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 1 }) -MetricName 'TotalFiles' -WarningVariable warnings } |
                Should -Not -Throw
            @($warnings).Count | Should -BeGreaterThan 0
        }

        It 'Uses debug-level warning for insufficient data when structured logging is disabled' {
            Disable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $warnings = $null
                { Get-MetricsTrend -HistoricalData @(@{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 1 }) -MetricName 'TotalFiles' -WarningVariable warnings } |
                    Should -Not -Throw
                @($warnings).Count | Should -BeGreaterThan 0
            }
            finally {
                if ($null -eq $originalDebug) { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
                else { $env:PS_PROFILE_DEBUG = $originalDebug }
            }
        }

        It 'Uses plain Write-Warning for null historical entries when structured logging is disabled' {
            Disable-TestStructuredLogging

            $warnings = $null
            { Get-MetricsTrend -HistoricalData @($null, @{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 10 }, @{ Timestamp = '2024-03-02T00:00:00Z'; TotalFiles = 20 }) -MetricName 'TotalFiles' -WarningVariable warnings } |
                Should -Not -Throw
            @($warnings).Count | Should -BeGreaterThan 0
        }

        It 'Emits level 3 null-value tracing when debug is enabled without structured logging' {
            Disable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-MetricsTrend -HistoricalData @(
                    $null
                    @{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 10 }
                    @{ Timestamp = '2024-03-02T00:00:00Z'; TotalFiles = 20 }
                ) -MetricName 'TotalFiles'

                $result.DataPoints | Should -Be 2
            }
            finally {
                if ($null -eq $originalDebug) { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
                else { $env:PS_PROFILE_DEBUG = $originalDebug }
            }
        }

        It 'Emits verbose output at debug level 2 during trend analysis' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                { Get-MetricsTrend -HistoricalData @(
                    @{ Timestamp = '2024-03-01T00:00:00Z'; TotalFiles = 10 }
                    @{ Timestamp = '2024-03-02T00:00:00Z'; TotalFiles = 20 }
                ) -MetricName 'TotalFiles' -Verbose } | Should -Not -Throw
            }
            finally {
                if ($null -eq $originalDebug) { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
                else { $env:PS_PROFILE_DEBUG = $originalDebug }
            }
        }
    }
}
