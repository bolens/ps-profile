<#
tests/unit/test-runner-analysis-edge-cases.tests.ps1

.SYNOPSIS
    Edge-case unit tests for failure, performance, and categorization analysis.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestCategorization.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestFailureAnalysis.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestPerformanceAnalysis.psm1') -Force -Global
}

Describe 'Test analysis edge cases' {
    Context 'Get-FailureAnalysis' {
        It 'Returns empty array when no failures are present' {
            Get-FailureAnalysis -TestResult @{ FailedTests = $null } | Should -Be @()
            Get-FailureAnalysis -TestResult @{} | Should -Be @()
        }

        It 'Groups failures by file and category' {
            $mockResult = @{
                FailedTests = @(
                    @{ Name = 'Unit failure A'; File = 'tests/unit/a.tests.ps1'; Tags = @('Unit'); ErrorRecord = @{ Exception = @{ Message = 'Error A' } } }
                    @{ Name = 'Unit failure B'; File = 'tests/unit/a.tests.ps1'; Tags = @('Unit'); ErrorRecord = @{ Exception = @{ Message = 'Error B' } } }
                    @{ Name = 'Integration failure'; File = 'tests/integration/b.tests.ps1'; Tags = @('Integration'); ErrorRecord = @{ Exception = @{ Message = 'Error C' } } }
                )
            }

            $analysis = Get-FailureAnalysis -TestResult $mockResult

            @($analysis.ByFile['tests/unit/a.tests.ps1']).Count | Should -Be 2
            @($analysis.ByCategory['Unit']).Count | Should -Be 2
            @($analysis.ByCategory['Integration']).Count | Should -Be 1
        }
    }

    Context 'Get-PerformanceAnalysis' {
        It 'Returns empty distribution when no passed tests have durations' {
            $analysis = Get-PerformanceAnalysis -TestResult @{
                Time        = [TimeSpan]::FromSeconds(1)
                PassedTests = @()
            }

            $analysis.SlowestTests | Should -Be @()
            $analysis.FastestTests | Should -Be @()
            $analysis.AverageDuration | Should -BeNullOrEmpty
            $analysis.PerformanceDistribution.Fast | Should -Be 0
        }

        It 'Buckets medium-duration tests correctly' {
            $analysis = Get-PerformanceAnalysis -TestResult @{
                Time        = [TimeSpan]::FromSeconds(2)
                PassedTests = @(
                    [PSCustomObject]@{ Name = 'MediumTest'; Duration = [TimeSpan]::FromMilliseconds(500); File = 'medium.ps1' }
                )
            }

            $analysis.PerformanceDistribution.Medium | Should -Be 1
            $analysis.PerformanceDistribution.Fast | Should -Be 0
            $analysis.AverageDuration.TotalMilliseconds | Should -BeGreaterThan 400
        }
    }

    Context 'Get-TestCategory' {
        It 'Prefers Performance tag over file path heuristics' {
            Get-TestCategory -Test @{
                Name = 'Generic test'
                File = 'tests/integration/something.tests.ps1'
                Tags = @('Performance')
            } | Should -Be 'Performance'
        }

        It 'Defaults to Unit when no tags or path hints match' {
            Get-TestCategory -Test @{
                Name = 'Generic helper test'
                File = 'tests/helpers/common.tests.ps1'
            } | Should -Be 'Unit'
        }
    }
}
