<#
tests/unit/test-runner-baseline-generation-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for BaselineGeneration module.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestEnvironment.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'BaselineGeneration.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'BaselineGenerationExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'BaselineGeneration extended scenarios' {
    Context 'New-PerformanceBaseline' {
        It 'Persists performance metrics when PerformanceData is supplied' {
            $outputPath = Join-Path $script:TempDir 'baseline-with-perf.json'
            $mockResult = @{
                TotalCount   = 12
                PassedCount  = 11
                FailedCount  = 1
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(8)
            }
            $performance = @{
                Duration        = [TimeSpan]::FromSeconds(8)
                PeakMemoryMB    = 512
                AverageMemoryMB = 384
                CPUUsage        = 55
            }

            $baseline = New-PerformanceBaseline -TestResult $mockResult -PerformanceData $performance -OutputPath $outputPath

            $baseline.Performance.PeakMemoryMB | Should -Be 512
            Test-Path -LiteralPath $outputPath | Should -Be $true

            $saved = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
            $saved.Performance.PeakMemoryMB | Should -Be 512
            $saved.Performance.CPUUsage | Should -Be 55
        }

        It 'Uses Duration property when Time is absent on test result' {
            $outputPath = Join-Path $script:TempDir 'baseline-duration-fallback.json'
            $mockResult = @{
                TotalCount   = 3
                PassedCount  = 3
                FailedCount  = 0
                SkippedCount = 0
                Duration     = [TimeSpan]::FromSeconds(6)
            }

            $baseline = New-PerformanceBaseline -TestResult $mockResult -OutputPath $outputPath

            $baseline.TestSummary.Duration.TotalSeconds | Should -Be 6

            $saved = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
            $saved.TestSummary.Duration | Should -Match '00:00:06'
        }

        It 'Captures environment metadata in saved baseline JSON' {
            $outputPath = Join-Path $script:TempDir 'baseline-environment.json'
            $mockResult = @{
                TotalCount   = 1
                PassedCount  = 1
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(1)
            }

            $null = New-PerformanceBaseline -TestResult $mockResult -OutputPath $outputPath
            $saved = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json

            $saved.Environment.PowerShellVersion | Should -Not -BeNullOrEmpty
            $saved.Environment.ProcessorCount | Should -BeGreaterThan 0
        }
    }
}
