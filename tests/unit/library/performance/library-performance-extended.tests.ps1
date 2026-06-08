<#
tests/unit/library-performance-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for performance aggregation edge cases.
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
    Import-Module (Join-Path $libPath 'performance' 'PerformanceAggregation.psm1') -DisableNameChecking -ErrorAction Stop -Global
}

AfterAll {
    Remove-Module PerformanceAggregation -ErrorAction SilentlyContinue -Force
}

Describe 'Performance extended scenarios' {
    Context 'Get-AggregatedMetrics' {
        It 'Preserves the operation name in the result object' {
            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ DurationMs = 25; Success = $true }
            ) -OperationName 'CustomOp'

            $result.OperationName | Should -Be 'CustomOp'
        }

        It 'Sums total duration across all metrics' {
            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ DurationMs = 40; Success = $true }
                [PSCustomObject]@{ DurationMs = 60; Success = $true }
            ) -OperationName 'TotalDuration'

            $result.TotalDurationMs | Should -Be 100
        }

        It 'Skips metrics missing DurationMs without failing' {
            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ Success = $true }
                [PSCustomObject]@{ DurationMs = 80; Success = $true }
            ) -OperationName 'PartialMetrics' -WarningAction SilentlyContinue

            $result.Count | Should -Be 1
            $result.AverageDurationMs | Should -Be 80
        }

        It 'Computes percentile fields for larger samples' {
            $metrics = 1..20 | ForEach-Object {
                [PSCustomObject]@{ DurationMs = $_ * 10; Success = $true }
            }

            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'Percentiles'
            $result.P95DurationMs | Should -BeGreaterThan $result.MedianDurationMs
            $result.P99DurationMs | Should -BeGreaterOrEqual $result.P95DurationMs
        }

        It 'Treats missing Success as neither success nor failure' {
            $result = Get-AggregatedMetrics -Metrics @(
                [PSCustomObject]@{ DurationMs = 50 }
                [PSCustomObject]@{ DurationMs = 50; Success = $true }
            ) -OperationName 'UnknownSuccess'

            $result.SuccessCount | Should -Be 1
            $result.FailureCount | Should -Be 0
            $result.Count | Should -Be 2
        }
    }
}
