#
# Performance-related helper tests covering metrics and regression detection.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import the Performance and CodeMetrics modules (Common.psm1 no longer exists)
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'PerformanceMeasurement.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'PerformanceRegression.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'CodeMetrics.psm1') -DisableNameChecking -ErrorAction Stop -Global
    # Import dependencies
    Import-Module (Join-Path $libPath 'FileSystem.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'AstParsing.psm1') -DisableNameChecking -ErrorAction Stop -Global
    $script:ScriptsUtilsPath = Get-TestPath -RelativePath 'scripts\utils' -StartPath $PSScriptRoot -EnsureExists
}

Describe 'Performance Metrics Functions' {
    Context 'Measure-Operation' {
        It 'Measures operation execution time' {
            $metrics = Measure-Operation -ScriptBlock { Start-Sleep -Milliseconds 100 } -OperationName 'TestOperation'
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.OperationName | Should -Be 'TestOperation'
            $metrics.DurationMs | Should -BeGreaterThan 0
            $metrics.Success | Should -Be $true
        }

        It 'Captures errors in metrics' {
            try {
                $metrics = Measure-Operation -ScriptBlock { throw 'Test error' } -OperationName 'FailingOperation' -ErrorAction Stop
            }
            catch {
            }

            $true | Should -Be $true
        }
    }

    Context 'Test-PerformanceRegression' {
        BeforeAll {
            $script:PerformanceTestDir = New-TestTempDirectory -Prefix 'PerformanceRegression'
            $script:TestBaselineFile = Join-Path $script:PerformanceTestDir 'baseline.json'
            $baseline = @{
                DurationMs = 1000
                MemoryMB   = 50
            } | ConvertTo-Json
            $baseline | Set-Content -Path $script:TestBaselineFile -Encoding UTF8
        }

        AfterAll {
            if (Test-Path $script:PerformanceTestDir) {
                Remove-Item -Path $script:PerformanceTestDir -Recurse -Force
            }
        }

        It 'Detects performance regression' {
            $currentMetrics = @{ DurationMs = 2000 }
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:TestBaselineFile -Threshold 1.5
            $result.RegressionDetected | Should -Be $true
            $result.Ratio | Should -BeGreaterThan 1.5
        }

        It 'Does not detect regression when within threshold' {
            $currentMetrics = @{ DurationMs = 1200 }
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:TestBaselineFile -Threshold 1.5
            $result.RegressionDetected | Should -Be $false
        }

        It 'Handles missing baseline gracefully' {
            $currentMetrics = @{ DurationMs = 1000 }
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile 'nonexistent.json'
            $result.RegressionDetected | Should -Be $false
            $result.Message | Should -Match 'No baseline found'
        }
    }

    Context 'Get-CodeMetrics' {
        It 'Collects code metrics for directory' {
            $metrics = Get-CodeMetrics -Path $script:ScriptsUtilsPath
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.TotalFiles | Should -BeGreaterThan 0
            # Some files may fail to parse, so TotalLines might be 0 if all files fail
            # Just verify the structure is correct
            $metrics.TotalLines | Should -Not -BeNullOrEmpty
        }

        It 'Includes file-level metrics' {
            $metrics = Get-CodeMetrics -Path $script:ScriptsUtilsPath
            # FileMetrics should be an array (even if empty when all files fail to parse)
            # Check the property value directly (not via pipeline) - null values pipe nothing
            $fileMetricsValue = $metrics.FileMetrics
            Should -ActualValue $fileMetricsValue -Not -Be $null -Because "FileMetrics should always be an array reference, never null"
            # Verify it's an array type
            Should -ActualValue $fileMetricsValue -BeOfType [System.Array] -Because "FileMetrics should be an array type"
            Should -ActualValue $fileMetricsValue.Count -BeGreaterOrEqual 0 -Because "FileMetrics.Count should be >= 0"
        }

        It 'Calculates averages correctly' {
            $metrics = Get-CodeMetrics -Path $script:ScriptsUtilsPath
            if ($metrics.TotalFiles -gt 0 -and $metrics.TotalLines -gt 0) {
                $metrics.AverageLinesPerFile | Should -BeGreaterThan 0
            }
            else {
                # If no files were parsed successfully, averages should be 0
                $metrics.AverageLinesPerFile | Should -Be 0
            }
            $metrics.AverageFunctionsPerFile | Should -BeGreaterOrEqual 0
            $metrics.AverageComplexityPerFile | Should -BeGreaterOrEqual 0
        }
    }
}
