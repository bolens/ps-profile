. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import the module under test
    $script:PerformanceAggregationPath = Join-Path $script:LibPath 'performance' 'PerformanceAggregation.psm1'
    Import-Module $script:PerformanceAggregationPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module PerformanceAggregation -ErrorAction SilentlyContinue -Force
}

Describe 'PerformanceAggregation Module Functions' {
    Context 'Get-AggregatedMetrics' {
        It 'Handles empty metrics array' {
            $result = Get-AggregatedMetrics -Metrics @() -OperationName 'Test'
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
            $result.AverageDurationMs | Should -Be 0
            $result.SuccessRate | Should -Be 0
        }

        It 'Aggregates multiple metrics correctly' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 100; Success = $true }
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
                [PSCustomObject]@{ DurationMs = 150; Success = $false }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.Count | Should -Be 3
            $result.AverageDurationMs | Should -BeGreaterThan 0
            $result.SuccessCount | Should -Be 2
            $result.FailureCount | Should -Be 1
        }

        It 'Calculates min and max durations' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 50; Success = $true }
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
                [PSCustomObject]@{ DurationMs = 100; Success = $true }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.MinDurationMs | Should -Be 50
            $result.MaxDurationMs | Should -Be 200
        }

        It 'Calculates median duration' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 50; Success = $true }
                [PSCustomObject]@{ DurationMs = 100; Success = $true }
                [PSCustomObject]@{ DurationMs = 150; Success = $true }
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.MedianDurationMs | Should -BeGreaterThan 0
        }

        It 'Calculates percentiles' {
            $metrics = 1..100 | ForEach-Object {
                [PSCustomObject]@{ DurationMs = $_; Success = $true }
            }
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.P50DurationMs | Should -BeGreaterThan 0
            $result.P95DurationMs | Should -BeGreaterThan 0
            $result.P99DurationMs | Should -BeGreaterThan 0
        }

        It 'Calculates success rate' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 100; Success = $true }
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
                [PSCustomObject]@{ DurationMs = 150; Success = $false }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.SuccessRate | Should -BeGreaterThan 0
            $result.SuccessRate | Should -BeLessOrEqual 100
        }

        It 'Handles hashtable input' {
            $metrics = @(
                @{ DurationMs = 100; Success = $true }
                @{ DurationMs = 200; Success = $true }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }

        It 'Skips null metrics' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 100; Success = $true }
                $null
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.Count | Should -Be 2
        }

        It 'Skips metrics without DurationMs' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 100; Success = $true }
                [PSCustomObject]@{ Success = $true }
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.Count | Should -Be 2
        }

        It 'Calculates total duration' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 100; Success = $true }
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result.TotalDurationMs | Should -Be 300
        }

        It 'Uses default OperationName when not specified' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 100; Success = $true }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics
            $result.OperationName | Should -Be 'Operations'
        }

        It 'Handles metrics with missing Success property' {
            $metrics = @(
                [PSCustomObject]@{ DurationMs = 100 }
                [PSCustomObject]@{ DurationMs = 200; Success = $true }
            )
            
            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName 'TestOp'
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
    }
}

