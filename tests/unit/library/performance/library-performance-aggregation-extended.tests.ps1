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
    }
}
