<#
tests/unit/TestReporting.tests.ps1

.SYNOPSIS
    Tests for the TestReporting module.
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

Describe 'TestReporting Module Tests' {
    Context 'Get-TestAnalysisReport' {
        It 'Analyzes test results comprehensively' {
            $mockResult = @{
                TotalCount   = 20
                PassedCount  = 18
                FailedCount  = 2
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(10)
                FailedTests  = @(
                    @{ Name = 'Test1'; File = 'test1.ps1'; ErrorRecord = @{ Exception = @{ Message = 'Error 1' } } }
                    @{ Name = 'Test2'; File = 'test2.ps1'; ErrorRecord = @{ Exception = @{ Message = 'Error 1' } } }
                )
            }

            $analysis = Get-TestAnalysisReport -TestResult $mockResult

            $analysis.Summary.TotalTests | Should -Be 20
            $analysis.Summary.SuccessRate | Should -Be 90
            $analysis.FailureAnalysis.MostCommonErrors.Count | Should -BeGreaterThan 0
            $analysis.Recommendations | Should -Contain "Address 2 failing test(s)"
        }
    }

    Context 'Get-FailureAnalysis' {
        It 'Groups failures by error message' {
            $mockResult = @{
                FailedTests = @(
                    @{ Name = 'Test1'; File = 'file1.ps1'; ErrorRecord = @{ Exception = @{ Message = 'Error A' } } }
                    @{ Name = 'Test2'; File = 'file2.ps1'; ErrorRecord = @{ Exception = @{ Message = 'Error A' } } }
                    @{ Name = 'Test3'; File = 'file3.ps1'; ErrorRecord = @{ Exception = @{ Message = 'Error B' } } }
                )
            }

            $analysis = Get-FailureAnalysis -TestResult $mockResult

            $analysis.ByErrorMessage['Error A'].Count | Should -Be 2
            $analysis.ByErrorMessage['Error B'].Count | Should -Be 1
            $analysis.MostCommonErrors[0].Count | Should -Be 2
        }
    }

    Context 'Get-PerformanceAnalysis' {
        It 'Analyzes test performance metrics' {
            $mockResult = @{
                PassedTests = @(
                    [PSCustomObject]@{ Name = 'FastTest'; Duration = [TimeSpan]::FromMilliseconds(50); File = 'fast.ps1' }
                    [PSCustomObject]@{ Name = 'SlowTest'; Duration = [TimeSpan]::FromSeconds(15); File = 'slow.ps1' }
                )
            }

            $analysis = Get-PerformanceAnalysis -TestResult $mockResult

            $analysis.SlowestTests[0].Name | Should -Be 'SlowTest'
            $analysis.FastestTests[0].Name | Should -Be 'FastTest'
            $analysis.PerformanceDistribution.VerySlow | Should -Be 1
            $analysis.PerformanceDistribution.Fast | Should -Be 1
        }
    }

    Context 'Get-TestCategory' {
        It 'Categorizes tests based on properties' {
            $unitTest = @{ Name = 'Unit Test'; Tags = @('Unit') }
            $integrationTest = @{ Name = 'Integration Test'; Tags = @('Integration') }
            $fileTest = @{ Name = 'File Test'; File = 'integration-test.ps1' }

            Get-TestCategory -Test $unitTest | Should -Be 'Unit'
            Get-TestCategory -Test $integrationTest | Should -Be 'Integration'
            Get-TestCategory -Test $fileTest | Should -Be 'Integration'
        }
    }

    Context 'New-CustomTestReport' {
        It 'Generates JSON report' {
            $mockResult = @{
                TotalCount   = 5
                PassedCount  = 4
                FailedCount  = 1
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(2)
            }

            $report = New-CustomTestReport -TestResult $mockResult -Format 'JSON'

            $parsed = $report | ConvertFrom-Json
            $parsed.Summary.Total | Should -Be 5
            $parsed.Summary.Passed | Should -Be 4
        }

        It 'Generates HTML report' {
            $mockResult = @{
                TotalCount   = 3
                PassedCount  = 3
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(1)
            }

            $report = New-CustomTestReport -TestResult $mockResult -Format 'HTML'

            $report | Should -Match '<!DOCTYPE html>'
            $report | Should -Match '<h1>Test Execution Report</h1>'
        }
    }

    Context 'New-PerformanceBaseline' {
        It 'Creates performance baseline file' {
            $mockResult = @{
                TotalCount   = 10
                PassedCount  = 9
                FailedCount  = 1
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(5)
            }

            $baselinePath = Join-Path $TestDrive 'test-baseline.json'

            $baseline = New-PerformanceBaseline -TestResult $mockResult -OutputPath $baselinePath

            $baseline.TestSummary.TotalTests | Should -Be 10
            Test-Path $baselinePath | Should -Be $true

            # Cleanup
            Remove-Item $baselinePath -ErrorAction SilentlyContinue
        }
    }

    Context 'Compare-PerformanceBaseline' {
        It 'Compares current results with baseline' {
            # Create a baseline file
            # Create a baseline file
            $date = Get-Date
            $prevDate = $date.AddDays(-1)
            $dateStr = $prevDate.ToString('o')
            
            $baselineData = @{
                GeneratedAt = $dateStr
                TestSummary = @{
                    TotalTests   = 10
                    PassedTests  = 10
                    FailedTests  = 0
                    SkippedTests = 0
                    Duration     = '00:00:05'
                }
                Performance = @{
                    Duration        = '00:00:05'
                    PeakMemoryMB    = 100
                    AverageMemoryMB = 80
                    CPUUsage        = 25
                }
                TestMetrics = @{
                    'SlowTest' = @{ Duration = '00:00:10' }
                }
                Environment = @{
                    IsCI              = $false
                    PowerShellVersion = "$($PSVersionTable.PSVersion)"
                    OS                = "$($PSVersionTable.OS)"
                    Platform          = "$($PSVersionTable.Platform)"
                    AvailableMemoryGB = 8
                    ProcessorCount    = 4
                }
            }

            $baselinePath = Join-Path $TestDrive 'baseline.json'
            $baselineData | ConvertTo-Json -Depth 10 | Out-File -FilePath $baselinePath

            # Current results (slower)
            $currentResult = @{
                TotalCount   = 10
                PassedCount  = 10
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(7) # 40% slower
                PassedTests  = @(
                    [PSCustomObject]@{ Name = 'SlowTest'; Duration = [TimeSpan]::FromSeconds(15); File = 'slow.ps1' }
                )
            }

            $comparison = Compare-PerformanceBaseline -TestResult $currentResult -BaselinePath $baselinePath

            $comparison.Success | Should -Be $true
            $comparison.Regressions | Should -Not -BeNullOrEmpty
            $comparison.OverallChange.DurationChange.ChangePercent | Should -BeGreaterThan 30

            # Cleanup
            Remove-Item $baselinePath -ErrorAction SilentlyContinue
        }
    }
}
