<#
tests/unit/test-runner-test-metrics-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestMetrics scoring boundaries.
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
    Import-Module (Join-Path $modulePath 'TestMetrics.psm1') -Force -Global
}

Describe 'TestMetrics extended scenarios' {
    Context 'Get-PerformanceGrade' {
        It 'Returns grade B for moderately long runs with moderate memory use' {
            $perf = @{
                Duration     = [TimeSpan]::FromSeconds(150)
                PeakMemoryMB = 600
                CPUUsage     = 40
            }

            Get-PerformanceGrade -PerformanceData $perf | Should -Be 'B'
        }

        It 'Returns grade C when duration and CPU penalties accumulate' {
            $perf = @{
                Duration     = [TimeSpan]::FromSeconds(320)
                PeakMemoryMB = 450
                CPUUsage     = 75
            }

            Get-PerformanceGrade -PerformanceData $perf | Should -Be 'C'
        }
    }

    Context 'Calculate-StabilityScore' {
        It 'Does not apply large-suite bonus for small test counts' {
            $smallSuite = [pscustomobject]@{
                TotalCount  = 10
                FailedCount = 0
            }

            Calculate-StabilityScore -TestResult $smallSuite | Should -Be 100
        }

        It 'Caps stability score at 100 even with large passing suites' {
            $largeSuite = [pscustomobject]@{
                TotalCount  = 100
                FailedCount = 0
            }

            Calculate-StabilityScore -TestResult $largeSuite | Should -Be 100
        }
    }

    Context 'Calculate-PerformanceScore' {
        It 'Applies moderate penalties for long duration and high memory' {
            $perf = @{
                Duration     = [TimeSpan]::FromSeconds(360)
                PeakMemoryMB = 1200
            }

            Calculate-PerformanceScore -PerformanceData $perf | Should -Be 75
        }

        It 'Returns a perfect score for fast, lightweight runs' {
            $perf = @{
                Duration     = [TimeSpan]::FromSeconds(20)
                PeakMemoryMB = 128
            }

            Calculate-PerformanceScore -PerformanceData $perf | Should -Be 100
        }
    }
}
