<#
tests/unit/TestExecution.tests.ps1

.SYNOPSIS
    Tests for the TestExecution module.
#>

BeforeAll {
    # Import test support
    . $PSScriptRoot/../TestSupport.ps1

    # Import the modules to test
    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'PesterConfig.psm1') -Force
    # Import TestDiscovery submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'TestPathResolution.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestPathUtilities.psm1') -Force
    # Import TestExecution submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'TestRetry.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestEnvironment.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestPerformanceMonitoring.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestTimeoutHandling.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestRecovery.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestSummaryGeneration.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestReporting.psm1') -Force
    # Import OutputUtils submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force
    Import-Module (Join-Path $modulePath 'OutputSanitizer.psm1') -Force
    Import-Module (Join-Path $modulePath 'OutputInterceptor.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -Force -Global

    # Set up test repository root (two levels up from tests/unit)
    $script:TestRepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
}

Describe 'TestExecution Module Tests' {
    Context 'Invoke-TestWithRetry' {
        It 'Executes script block successfully on first attempt' {
            $state = @{ executed = $false; attempts = 0 }

            $result = Invoke-TestWithRetry -ScriptBlock {
                $state.executed = $true
                $state.attempts++
                return @{ PassedCount = 1; FailedCount = 0 }
            }

            $state.executed | Should -Be $true
            $state.attempts | Should -Be 1
            $result.PassedCount | Should -Be 1
        }

        It 'Retries on failure up to MaxRetries' {
            $state = @{ attempts = 0 }

            $result = Invoke-TestWithRetry -ScriptBlock {
                $state.attempts++
                if ($state.attempts -lt 3) {
                    throw 'Test failed'
                }
                return @{ PassedCount = 1; FailedCount = 0 }
            } -MaxRetries 3 -WarningAction SilentlyContinue

            $state.attempts | Should -Be 3
            $result.PassedCount | Should -Be 1
        }

        It 'Throws exception after exhausting retries' {
            $state = @{ attempts = 0 }

            { Invoke-TestWithRetry -ScriptBlock {
                    $state.attempts++
                    throw 'Persistent failure'
                } -MaxRetries 2 -WarningAction SilentlyContinue } | Should -Throw

            $state.attempts | Should -Be 3 # Initial + 2 retries
        }

        It 'Applies exponential backoff' {
            $state = @{ attempts = 0; delays = @() }

            $startTime = Get-Date
            Invoke-TestWithRetry -ScriptBlock {
                $state.attempts++
                if ($state.attempts -lt 3) {
                    $state.delays += (Get-Date) - $startTime
                    throw 'Test failed'
                }
                return @{ PassedCount = 1; FailedCount = 0 }
            } -MaxRetries 2 -ExponentialBackoff -RetryDelaySeconds 1 -WarningAction SilentlyContinue

            $state.attempts | Should -Be 3
            # Verify delays increase exponentially (approximately)
            $state.delays[1].TotalSeconds | Should -BeGreaterThan $state.delays[0].TotalSeconds
        }
    }

    Context 'Measure-TestPerformance' {
        It 'Measures execution time' {
            $result = Measure-TestPerformance -ScriptBlock {
                Start-Sleep -Milliseconds 100
                return 'test result'
            }

            $result.Result | Should -Be 'test result'
            $result.Performance.Duration | Should -Not -BeNullOrEmpty
            $result.Performance.Duration.TotalMilliseconds | Should -BeGreaterThan 90
        }

        It 'Tracks memory usage when requested' {
            $result = Measure-TestPerformance -ScriptBlock {
                $data = 1..1000
                return $data
            } -TrackMemory

            $result.Performance.PeakMemoryMB | Should -Not -BeNullOrEmpty
            $result.Performance.AverageMemoryMB | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-TestEnvironment' {
        It 'Detects environment information' {
            $env = Get-TestEnvironment

            $env.IsCI | Should -Not -BeNullOrEmpty
            $env.PowerShellVersion | Should -Not -BeNullOrEmpty
            # $env.OS can be null on some systems
            # $env.Platform can be null on Windows PowerShell
            $env.ProcessorCount | Should -BeGreaterThan 0
        }

        It 'Detects CI environment variables' {
            # Mock CI environment
            $originalCI = $env:CI
            $env:CI = 'true'

            try {
                $env = Get-TestEnvironment
                $env.IsCI | Should -Be $true
            }
            finally {
                $env:CI = $originalCI
            }
        }

        It 'Detects available tools' {
            $env = Get-TestEnvironment

            # Git should be available in most development environments
            $env.HasGit | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-TestEnvironmentHealth' {
        It 'Checks module availability' {
            $health = Test-TestEnvironmentHealth -CheckModules

            $health.Passed | Should -Not -BeNullOrEmpty
            $health.Checks | Should -Not -BeNullOrEmpty

            $pesterCheck = $health.Checks | Where-Object { $_.Name -eq 'Module: Pester' }
            $pesterCheck | Should -Not -BeNullOrEmpty
        }

        It 'Checks path existence' {
            $health = Test-TestEnvironmentHealth -CheckPaths

            $health.Checks | Should -Not -BeNullOrEmpty

            $testsCheck = $health.Checks | Where-Object { $_.Name -eq 'Path: tests' }
            $testsCheck | Should -Not -BeNullOrEmpty
            $testsCheck.Passed | Should -Be $true
        }

        It 'Checks tool availability' {
            $health = Test-TestEnvironmentHealth -CheckTools

            $health.Checks | Should -Not -BeNullOrEmpty

            $gitCheck = $health.Checks | Where-Object { $_.Name -eq 'Tool: git' }
            $gitCheck | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-TestExecutionSummary' {
        It 'Creates execution summary from test results' {
            $mockResult = @{
                TotalCount        = 10
                PassedCount       = 8
                FailedCount       = 1
                SkippedCount      = 1
                InconclusiveCount = 0
                NotRunCount       = 0
                Time              = [TimeSpan]::FromSeconds(5)
            }

            $mockEnv = @{
                IsCI              = $false
                PowerShellVersion = $PSVersionTable.PSVersion
            }

            $summary = New-TestExecutionSummary -TestResult $mockResult -EnvironmentInfo $mockEnv

            $summary.TestResults.Total | Should -Be 10
            $summary.Success | Should -Be $false
            $summary.TestResults.Passed | Should -Be 8
            $summary.TestResults.Failed | Should -Be 1
            $summary.Recommendations | Should -Contain "Review 1 failed tests"
        }
    }
}
