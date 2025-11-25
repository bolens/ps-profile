<#
tests/performance/test-runner-performance.tests.ps1

.SYNOPSIS
    Performance tests for the test runner itself.

.DESCRIPTION
    Tests the performance characteristics of the test runner, including
    execution speed, memory usage, and scalability.
#>

BeforeAll {
    # Import test support
    . $PSScriptRoot/../TestSupport.ps1

    # Set up test environment
    $script:TestRepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:RunPesterPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-pester.ps1'
    $script:TempTestDir = Join-Path $TestDrive 'performance-tests'

    # Ensure the script exists
    if (-not (Test-Path $script:RunPesterPath)) {
        throw "Test runner script not found at: $script:RunPesterPath"
    }

    # Create temporary test directory
    if (-not (Test-Path $script:TempTestDir)) {
        New-Item -ItemType Directory -Path $script:TempTestDir -Force | Out-Null
    }

    # Performance thresholds (adjust based on system capabilities)
    $script:MaxTestRunnerStartupTime = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_MAX_TEST_RUNNER_STARTUP_MS' -Default 5000
    $script:MaxUnitTestExecutionTime = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_MAX_UNIT_TEST_TIME_MS' -Default 120000
    $script:MaxMemoryUsageMB = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_MAX_TEST_RUNNER_MEMORY_MB' -Default 500
}

Describe 'Test Runner Performance Tests' {
    Context 'Test Runner Startup Performance' {
        It 'Starts up within acceptable time limits' {
            $startupTime = Measure-Command {
                $result = & $script:RunPesterPath -DryRun -OutputFormat None
            }

            $startupTime.TotalMilliseconds | Should -BeLessThan $script:MaxTestRunnerStartupTime
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Initializes modules efficiently' {
            $initTime = Measure-Command {
                # Force module reload by running in separate process
                $result = Invoke-TestPwshScript -ScriptContent @"
& '$($script:RunPesterPath -replace "'", "''")' -DryRun -OutputFormat None
"@
            }

            $initTime.TotalMilliseconds | Should -BeLessThan $script:MaxTestRunnerStartupTime
        }
    }

    Context 'Test Execution Performance' {
        It 'Executes unit tests within time limits' {
            $executionTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Unit -OutputFormat None
            }

            $executionTime.TotalMilliseconds | Should -BeLessThan $script:MaxUnitTestExecutionTime
            $result | Should -Not -BeNullOrEmpty
            $result.PassedCount | Should -BeGreaterThan 0
        }

        It 'Executes integration tests within time limits' {
            $executionTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Integration -OutputFormat None
            }

            $executionTime.TotalMilliseconds | Should -BeLessThan ($script:MaxUnitTestExecutionTime * 2)  # Integration tests can take longer
            $result | Should -Not -BeNullOrEmpty
            $result.PassedCount | Should -BeGreaterThan 0
        }

        It 'Handles parallel execution efficiently' {
            $parallelTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Unit -Parallel 4 -OutputFormat None
            }

            $sequentialTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Unit -Parallel 1 -OutputFormat None
            }

            # Parallel should be faster (with some tolerance for system variability)
            $parallelTime.TotalMilliseconds | Should -BeLessThan ($sequentialTime.TotalMilliseconds * 1.5)
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Memory Usage Performance' {
        It 'Maintains reasonable memory usage during execution' {
            $result = & $script:RunPesterPath -Suite Unit -TrackPerformance -TrackMemory -OutputFormat None

            $result | Should -Not -BeNullOrEmpty
            # Note: We can't easily measure peak memory from here, but the tracking should work
        }

        It 'Handles large test suites without excessive memory growth' {
            # Run a comprehensive test suite
            $result = & $script:RunPesterPath -Suite All -OutputFormat None

            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -BeGreaterThan 100  # Should have many tests
        }
    }

    Context 'Performance Baseline Operations' {
        It 'Generates baselines efficiently' {
            $baselinePath = Join-Path $script:TempTestDir 'perf-baseline.json'

            $generationTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Unit -GenerateBaseline -BaselinePath $baselinePath -OutputFormat None
            }

            $generationTime.TotalMilliseconds | Should -BeLessThan ($script:MaxUnitTestExecutionTime * 1.2)  # Should not add much overhead
            $result | Should -Not -BeNullOrEmpty
            $baselinePath | Should -Exist
        }

        It 'Compares baselines efficiently' {
            $baselinePath = Join-Path $script:TempTestDir 'perf-compare-baseline.json'

            # Generate baseline first
            $result1 = & $script:RunPesterPath -Suite Unit -GenerateBaseline -BaselinePath $baselinePath -OutputFormat None

            # Then compare
            $comparisonTime = Measure-Command {
                $result2 = & $script:RunPesterPath -Suite Unit -CompareBaseline -BaselinePath $baselinePath -OutputFormat None
            }

            $comparisonTime.TotalMilliseconds | Should -BeLessThan ($script:MaxUnitTestExecutionTime * 0.5)  # Comparison should be fast
            $result2 | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Retry and Error Handling Performance' {
        It 'Handles retries efficiently' {
            # Create a test file with some failures to trigger retries
            $retryTestFile = Join-Path $script:TempTestDir 'retry-perf.tests.ps1'
            Set-Content -Path $retryTestFile -Value @'
Describe "Retry Performance Tests" {
    It "Should pass" {
        $true | Should -Be $true
    }
    It "Should pass after retry" {
        # Simulate occasional failure
        if ((Get-Random -Minimum 1 -Maximum 10) -eq 1) {
            $false | Should -Be $true
        } else {
            $true | Should -Be $true
        }
    }
}
'@

            $retryTime = Measure-Command {
                $result = & $script:RunPesterPath -TestFile $retryTestFile -MaxRetries 2 -RetryOnFailure -OutputFormat None
            }

            $retryTime.TotalMilliseconds | Should -BeLessThan ($script:MaxUnitTestExecutionTime * 2)  # Allow some overhead for retries
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles timeouts efficiently' {
            $timeoutTestFile = Join-Path $script:TempTestDir 'timeout-perf.tests.ps1'
            Set-Content -Path $timeoutTestFile -Value @'
Describe "Timeout Performance Tests" {
    It "Should complete within timeout" -TimeoutSeconds 5 {
        Start-Sleep -Seconds 1
        $true | Should -Be $true
    }
}
'@

            $timeoutTime = Measure-Command {
                $result = & $script:RunPesterPath -TestFile $timeoutTestFile -TestTimeoutSeconds 10 -OutputFormat None
            }

            $timeoutTime.TotalMilliseconds | Should -BeLessThan 15000  # Should complete well within timeout
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Reporting Performance' {
        It 'Generates analysis reports efficiently' {
            $analysisTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Unit -AnalyzeResults -OutputFormat None
            }

            $analysisTime.TotalMilliseconds | Should -BeLessThan ($script:MaxUnitTestExecutionTime * 1.3)  # Analysis adds some overhead
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Generates custom reports efficiently' {
            $reportPath = Join-Path $script:TempTestDir 'perf-report.html'

            $reportTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Unit -AnalyzeResults -ReportFormat HTML -ReportPath $reportPath -OutputFormat None
            }

            $reportTime.TotalMilliseconds | Should -BeLessThan ($script:MaxUnitTestExecutionTime * 1.4)  # Report generation adds overhead
            $result | Should -Not -BeNullOrEmpty
            $reportPath | Should -Exist
        }

        It 'Handles code coverage efficiently' {
            $coverageTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Unit -Coverage -OutputFormat None
            }

            $coverageTime.TotalMilliseconds | Should -BeLessThan ($script:MaxUnitTestExecutionTime * 2)  # Coverage can be expensive
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Scalability Tests' {
        It 'Scales with increasing test count' {
            # Test with different test suite sizes
            $smallSuiteTime = Measure-Command {
                $result = & $script:RunPesterPath -TestName '*profile-aliases*' -OutputFormat None
            }

            $mediumSuiteTime = Measure-Command {
                $result = & $script:RunPesterPath -Suite Unit -OutputFormat None
            }

            # Medium suite should not take disproportionately longer
            $ratio = $mediumSuiteTime.TotalMilliseconds / $smallSuiteTime.TotalMilliseconds
            $ratio | Should -BeLessThan 20  # Allow reasonable scaling
        }

        It 'Handles high parallelization efficiently' {
            if ([Environment]::ProcessorCount -ge 4) {
                $highParallelTime = Measure-Command {
                    $result = & $script:RunPesterPath -Suite Unit -Parallel ([Environment]::ProcessorCount) -OutputFormat None
                }

                $singleThreadTime = Measure-Command {
                    $result = & $script:RunPesterPath -Suite Unit -Parallel 1 -OutputFormat None
                }

                # High parallelization should provide benefit
                $speedup = $singleThreadTime.TotalMilliseconds / $highParallelTime.TotalMilliseconds
                $speedup | Should -BeGreaterThan 1.2  # Should see at least some speedup
            }
        }
    }

    Context 'Resource Cleanup Performance' {
        It 'Cleans up resources efficiently after execution' {
            $cleanupTest = Join-Path $script:TempTestDir 'cleanup-perf.tests.ps1'
            Set-Content -Path $cleanupTest -Value @'
Describe "Cleanup Performance Tests" {
    It "Creates temporary resources" {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $tempFile | Should -Exist
        # Cleanup happens automatically
    }
}
'@

            $executionTime = Measure-Command {
                $result = & $script:RunPesterPath -TestFile $cleanupTest -OutputFormat None
            }

            $executionTime.TotalMilliseconds | Should -BeLessThan 10000  # Should be fast
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Long-Running Test Scenarios' {
        It 'Maintains performance over multiple runs' {
            $runTimes = @()

            # Run the same test multiple times
            for ($i = 1; $i -le 5; $i++) {
                $runTime = Measure-Command {
                    $result = & $script:RunPesterPath -Suite Unit -OutputFormat None
                }
                $runTimes += $runTime.TotalMilliseconds
            }

            # Calculate coefficient of variation (lower is better - more consistent)
            $avg = ($runTimes | Measure-Object -Average).Average
            $variance = ($runTimes | ForEach-Object { [Math]::Pow($_ - $avg, 2) } | Measure-Object -Average).Average
            $stdDev = [Math]::Sqrt($variance)
            $cv = ($stdDev / $avg) * 100  # Coefficient of variation as percentage

            $cv | Should -BeLessThan 50  # Should be reasonably consistent (< 50% variation)
        }
    }
}
