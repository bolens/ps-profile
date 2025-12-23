. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Performance Module Functions' {
    BeforeAll {
        # Import the Performance modules (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'performance' 'PerformanceAggregation.psm1') -DisableNameChecking -ErrorAction Stop -Global
    }

    Context 'Get-AggregatedMetrics' {
        It 'Handles empty metrics array' {
            $result = Get-AggregatedMetrics -Metrics @() -OperationName 'Test'
            $result.Count | Should -Be 0
            $result.AverageDurationMs | Should -Be 0
            $result.SuccessRate | Should -Be 0
        }

        It 'Aggregates multiple metrics correctly' {
            $metrics = @(
                @{ DurationMs = 100; Success = $true }
                @{ DurationMs = 200; Success = $true }
                @{ DurationMs = 150; Success = $false }
            )

            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.Count | Should -Be 3
            $result.AverageDurationMs | Should -BeGreaterThan 0
            $result.SuccessCount | Should -Be 2
            $result.FailureCount | Should -Be 1
            $result.SuccessRate | Should -BeGreaterThan 0
        }

        It 'Calculates min and max durations' {
            $metrics = @(
                @{ DurationMs = 50; Success = $true }
                @{ DurationMs = 200; Success = $true }
                @{ DurationMs = 100; Success = $true }
            )

            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.MinDurationMs | Should -Be 50
            $result.MaxDurationMs | Should -Be 200
        }
    }
}
