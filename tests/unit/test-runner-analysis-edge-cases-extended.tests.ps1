<#
tests/unit/test-runner-analysis-edge-cases-extended.tests.ps1

.SYNOPSIS
    Extended edge-case tests for failure, performance, and categorization analysis.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestCategorization.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestFailureAnalysis.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestPerformanceAnalysis.psm1') -Force -Global
}

Describe 'Test analysis extended edge cases' {
    Context 'Get-FailureAnalysis' {
        It 'Preserves failure error messages in grouped results' {
            $analysis = Get-FailureAnalysis -TestResult @{
                FailedTests = @(
                    @{
                        Name        = 'Broken assertion'
                        File        = 'tests/unit/sample.tests.ps1'
                        Tags        = @('Unit')
                        ErrorRecord = @{ Exception = @{ Message = 'Expected 1 but got 2' } }
                    }
                )
            }

            $analysis.ByFile['tests/unit/sample.tests.ps1'][0].ErrorRecord.Exception.Message |
                Should -Be 'Expected 1 but got 2'
        }

        It 'Groups multiple categories independently' {
            $analysis = Get-FailureAnalysis -TestResult @{
                FailedTests = @(
                    @{ Name = 'Perf fail'; File = 'tests/performance/a.tests.ps1'; Tags = @('Performance'); ErrorRecord = @{ Exception = @{ Message = 'slow' } } }
                    @{ Name = 'Unit fail'; File = 'tests/unit/b.tests.ps1'; Tags = @('Unit'); ErrorRecord = @{ Exception = @{ Message = 'bad' } } }
                )
            }

            @($analysis.ByCategory['Performance']).Count | Should -Be 1
            @($analysis.ByCategory['Unit']).Count | Should -Be 1
        }
    }

    Context 'Get-PerformanceAnalysis' {
        It 'Buckets fast tests under 100ms' {
            $analysis = Get-PerformanceAnalysis -TestResult @{
                Time        = [TimeSpan]::FromMilliseconds(50)
                PassedTests = @(
                    [PSCustomObject]@{ Name = 'FastTest'; Duration = [TimeSpan]::FromMilliseconds(25); File = 'fast.tests.ps1' }
                )
            }

            $analysis.PerformanceDistribution.Fast | Should -Be 1
            $analysis.PerformanceDistribution.Medium | Should -Be 0
        }

        It 'Identifies very slow tests over ten seconds' {
            $analysis = Get-PerformanceAnalysis -TestResult @{
                Time        = [TimeSpan]::FromSeconds(12)
                PassedTests = @(
                    [PSCustomObject]@{ Name = 'VerySlowTest'; Duration = [TimeSpan]::FromSeconds(11); File = 'slow.tests.ps1' }
                )
            }

            $analysis.PerformanceDistribution.VerySlow | Should -Be 1
            $analysis.SlowestTests[0].Name | Should -Be 'VerySlowTest'
        }
    }

    Context 'Get-TestCategory' {
        It 'Prefers Integration tag over file path heuristics' {
            Get-TestCategory -Test @{
                Name = 'Generic test'
                File = 'tests/unit/something.tests.ps1'
                Tags = @('Integration')
            } | Should -Be 'Integration'
        }

        It 'Detects performance tests from file path naming' {
            Get-TestCategory -Test @{
                Name = 'Generic test'
                File = 'tests/performance/profile-startup-performance.tests.ps1'
            } | Should -Be 'Performance'
        }
    }
}
