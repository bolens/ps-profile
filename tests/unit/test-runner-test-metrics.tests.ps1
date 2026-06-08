<#
tests/unit/test-runner-test-metrics.tests.ps1

.SYNOPSIS
    Unit tests for TestMetrics module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestMetrics.psm1') -Force -Global

    function script:New-MockTestResult {
        param(
            [int]$Total = 50,
            [int]$Failed = 0
        )

        return [pscustomobject]@{
            TotalCount  = $Total
            FailedCount = $Failed
        }
    }
}

Describe 'TestMetrics Module' {
    Context 'Get-PerformanceGrade' {
        It 'Returns N/A when performance data is missing' {
            Get-PerformanceGrade -PerformanceData $null | Should -Be 'N/A'
        }

        It 'Returns A for fast execution with modest resource use' {
            $perf = @{
                Duration     = [TimeSpan]::FromSeconds(30)
                PeakMemoryMB = 256
                CPUUsage     = 40
            }

            Get-PerformanceGrade -PerformanceData $perf | Should -Be 'A'
        }

        It 'Penalizes long duration and high memory usage' {
            $perf = @{
                Duration     = [TimeSpan]::FromSeconds(400)
                PeakMemoryMB = 1500
                CPUUsage     = 95
            }

            Get-PerformanceGrade -PerformanceData $perf | Should -Be 'F'
        }
    }

    Context 'Calculate-TestCoverage' {
        It 'Returns zero for empty results' {
            Calculate-TestCoverage -TestResult $null | Should -Be 0
            Calculate-TestCoverage -TestResult ([pscustomobject]@{ TotalCount = 0; FailedCount = 0 }) | Should -Be 0
        }

        It 'Caps coverage score and reduces it when tests fail' {
            $passing = New-MockTestResult -Total 60 -Failed 0
            $failing = New-MockTestResult -Total 60 -Failed 5

            Calculate-TestCoverage -TestResult $passing | Should -Be 100
            Calculate-TestCoverage -TestResult $failing | Should -Be 90
        }
    }

    Context 'Calculate-StabilityScore' {
        It 'Reflects failure rate and rewards larger suites' {
            $stable = New-MockTestResult -Total 60 -Failed 0
            $unstable = New-MockTestResult -Total 10 -Failed 5

            Calculate-StabilityScore -TestResult $stable | Should -Be 100
            Calculate-StabilityScore -TestResult $unstable | Should -Be 50
        }
    }

    Context 'Calculate-PerformanceScore' {
        It 'Returns neutral score without data' {
            Calculate-PerformanceScore -PerformanceData $null | Should -Be 50
        }

        It 'Penalizes very long runs and high memory' {
            $perf = @{
                Duration     = [TimeSpan]::FromSeconds(700)
                PeakMemoryMB = 2500
            }

            Calculate-PerformanceScore -PerformanceData $perf | Should -BeLessThan 50
        }
    }
}
