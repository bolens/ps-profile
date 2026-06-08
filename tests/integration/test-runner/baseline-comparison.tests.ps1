<#
tests/integration/test-runner/baseline-comparison.tests.ps1

.SYNOPSIS
    Integration tests for performance baseline workflows.

.DESCRIPTION
    Tests baseline module functions directly and validates run-pester.ps1
    baseline-related CLI switches via dry-run mode.
#>

BeforeAll {
    . (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RunPesterPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-pester.ps1'
    $script:DryRunTestFile = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'
    $script:TempTestDir = New-TestTempDirectory -Prefix 'BaselineComparison'

    $modulePath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'BaselineGeneration.psm1') -Force
    Import-Module (Join-Path $modulePath 'BaselineComparison.psm1') -Force

    function Clear-TestRunnerFlag {
        $env:PS_PROFILE_TEST_RUNNER_ACTIVE = $null
    }
}

Describe 'Performance Baseline Workflows' {
    BeforeEach { Clear-TestRunnerFlag }

    Context 'Baseline module functions' {
        It 'Creates baseline JSON with expected structure' {
            $baselinePath = Join-Path $script:TempTestDir 'module-baseline.json'
            $testResult = [PSCustomObject]@{
                TotalCount   = 12
                PassedCount  = 11
                FailedCount  = 1
                SkippedCount = 0
                Duration     = [TimeSpan]::FromSeconds(4.2)
            }
            $performanceData = @{
                Duration        = 4.2
                PeakMemoryMB    = 128
                AverageMemoryMB = 96
                CPUUsage        = 42.5
            }

            $baseline = New-PerformanceBaseline -TestResult $testResult -PerformanceData $performanceData -OutputPath $baselinePath

            $baseline | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $baselinePath | Should -Be $true

            $saved = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json
            $saved.TestSummary.TotalTests | Should -Be 12
            $saved.TestSummary.PassedTests | Should -Be 11
            $saved.Performance.PeakMemoryMB | Should -Be 128
        }

        It 'Compares against an existing baseline file' {
            $baselinePath = Join-Path $script:TempTestDir 'compare-baseline.json'
            $baseline = @{
                GeneratedAt = (Get-Date).ToString('o')
                TestSummary = @{
                    TotalTests   = 10
                    PassedTests  = 10
                    FailedTests  = 0
                    SkippedTests = 0
                    Duration     = '00:00:05'
                }
                Performance = @{
                    Duration = 5
                }
            } | ConvertTo-Json -Depth 5
            Set-Content -LiteralPath $baselinePath -Value $baseline -Encoding UTF8

            $currentResult = [PSCustomObject]@{
                TotalCount   = 10
                PassedCount  = 10
                FailedCount  = 0
                SkippedCount = 0
                Duration     = [TimeSpan]::FromSeconds(5.2)
            }

            $comparison = Compare-PerformanceBaseline -TestResult $currentResult -BaselinePath $baselinePath -Threshold 10
            $comparison.Success | Should -Be $true
        }

        It 'Handles corrupted baseline files gracefully' {
            $corruptedPath = Join-Path $script:TempTestDir 'corrupted-baseline.json'
            Set-Content -LiteralPath $corruptedPath -Value '{ invalid json' -Encoding UTF8

            $currentResult = [PSCustomObject]@{
                TotalCount   = 1
                PassedCount  = 1
                FailedCount  = 0
                SkippedCount = 0
                Duration     = [TimeSpan]::FromSeconds(1)
            }

            $comparison = Compare-PerformanceBaseline -TestResult $currentResult -BaselinePath $corruptedPath
            $comparison.Success | Should -Be $false
        }
    }

    Context 'run-pester baseline CLI switches' {
        It 'Accepts GenerateBaseline in dry-run mode' {
            $baselinePath = Join-Path $script:TempTestDir 'cli-baseline.json'
            { & $script:RunPesterPath -DryRun -GenerateBaseline -BaselinePath $baselinePath -TestFile $script:DryRunTestFile } | Should -Not -Throw
        }

        It 'Accepts CompareBaseline in dry-run mode' {
            $baselinePath = Join-Path $script:TempTestDir 'cli-compare-baseline.json'
            { & $script:RunPesterPath -DryRun -CompareBaseline -BaselinePath $baselinePath -BaselineThreshold 8 -TestFile $script:DryRunTestFile } | Should -Not -Throw
        }

        It 'Accepts baseline switches with performance tracking flags' {
            $baselinePath = Join-Path $script:TempTestDir 'cli-perf-baseline.json'
            {
                & $script:RunPesterPath -DryRun -GenerateBaseline -CompareBaseline -BaselinePath $baselinePath `
                    -TrackPerformance -TrackMemory -TrackCPU -TestFile $script:DryRunTestFile
            } | Should -Not -Throw
        }
    }
}
