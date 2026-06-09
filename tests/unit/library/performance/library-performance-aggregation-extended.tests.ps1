<#
tests/unit/library-performance-aggregation-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-AggregatedMetrics edge cases and statistics.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceAggregation.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module PerformanceAggregation -ErrorAction SilentlyContinue -Force
}

Describe 'PerformanceAggregation extended scenarios' {
    Context 'Get-AggregatedMetrics' {
        It 'Returns zeroed statistics when every metric entry is null' {
            $result = Get-AggregatedMetrics -Metrics @($null, $null) -OperationName 'NullOnly'

            $result.Count | Should -Be 0
            $result.AverageDurationMs | Should -Be 0
            $result.SuccessRate | Should -Be 0
            $result.OperationName | Should -Be 'NullOnly'
        }

        It 'Calculates median equal to the sole duration value' {
            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ DurationMs = 42; Success = $true }
            ) -OperationName 'SingleMetric'

            $result.MedianDurationMs | Should -Be 42
            $result.MinDurationMs | Should -Be 42
            $result.MaxDurationMs | Should -Be 42
        }

        It 'Treats missing Success values as neither success nor failure' {
            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ DurationMs = 100 }
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
            ) -OperationName 'UnknownSuccess'

            $result.SuccessCount | Should -Be 1
            $result.FailureCount | Should -Be 0
            $result.Count | Should -Be 2
        }

        It 'Reports zero success rate when all operations fail' {
            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ DurationMs = 100; Success = $false }
                [PSCustomObject]@{ DurationMs = 200; Success = $false }
            ) -OperationName 'AllFailed'

            $result.SuccessCount | Should -Be 0
            $result.FailureCount | Should -Be 2
            $result.SuccessRate | Should -Be 0
        }

        It 'Computes even-count median as the average of middle values' {
            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ DurationMs = 10; Success = $true }
                [PSCustomObject]@{ DurationMs = 30; Success = $true }
            ) -OperationName 'EvenMedian'

            $result.MedianDurationMs | Should -Be 20
        }

        It 'Aggregates dictionary-shaped metric entries' {
            $result = Get-AggregatedMetrics -Metrics @(
                @{ DurationMs = 50; Success = $true }
                @{ DurationMs = 150; Success = $false }
            ) -OperationName 'DictionaryMetrics'

            $result.Count | Should -Be 2
            $result.TotalDurationMs | Should -Be 200
            $result.SuccessCount | Should -Be 1
            $result.FailureCount | Should -Be 1
        }

        It 'Calculates percentile fields for multi-value metric sets' {
            $metrics = 1..20 | ForEach-Object {
                [PSCustomObject]@{ DurationMs = $_ * 10; Success = $true }
            }
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'Percentiles'

            $result.P50DurationMs | Should -BeGreaterThan 0
            $result.P95DurationMs | Should -BeGreaterOrEqual $result.P50DurationMs
            $result.P99DurationMs | Should -BeGreaterOrEqual $result.P95DurationMs
        }

        It 'Uses plain warnings when structured logging is disabled for null metrics' {
            $originalFlag = $env:PS_PROFILE_PERFORMANCE_AGGREGATION_DISABLE_STRUCTURED_WARNING
            $env:PS_PROFILE_PERFORMANCE_AGGREGATION_DISABLE_STRUCTURED_WARNING = '1'

            try {
                $result = Get-AggregatedMetrics -Metrics @($null) -OperationName 'PlainNull'
                $result.Count | Should -Be 0
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PERFORMANCE_AGGREGATION_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PERFORMANCE_AGGREGATION_DISABLE_STRUCTURED_WARNING = $originalFlag
                }
            }
        }

        It 'Emits structured warnings for invalid metrics when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ Success = $true }
            ) -OperationName 'MissingDuration'

            $result.Count | Should -Be 0
        }

        It 'Emits debug output when PS_PROFILE_DEBUG is enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-AggregatedMetrics -Metrics @(
                    [PSCustomObject]@{ DurationMs = 12; Success = $true }
                    [PSCustomObject]@{ DurationMs = 18; Success = $true }
                ) -OperationName 'DebugAggregation'

                $result.AverageDurationMs | Should -Be 15
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
    }
}
