<#
tests/unit/test-runner-failure-analysis-grouping-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-FailureAnalysis grouping by file and category.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestCategorization.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestFailureAnalysis.psm1') -Force -Global

    function script:New-MockFailure {
        param(
            [string]$Name,
            [string]$File,
            [string]$Message,
            [string[]]$Tags = @()
        )

        return @{
            Name        = $Name
            File        = $File
            Tags        = $Tags
            ErrorRecord = @{
                Exception = @{
                    Message = $Message
                }
            }
        }
    }
}

Describe 'TestFailureAnalysis grouping extended scenarios' {
    Context 'Get-FailureAnalysis' {
        It 'Returns an empty array when there are no failures' {
            $analysis = Get-FailureAnalysis -TestResult @{ FailedTests = @() }

            @($analysis).Count | Should -Be 0
        }

        It 'Groups failures by file path' {
            $sharedFile = 'tests/unit/shared-target.tests.ps1'
            $mockResult = @{
                FailedTests = @(
                    (New-MockFailure -Name 'First' -File $sharedFile -Message 'Error A')
                    (New-MockFailure -Name 'Second' -File $sharedFile -Message 'Error B')
                    (New-MockFailure -Name 'Third' -File 'tests/unit/other.tests.ps1' -Message 'Error C')
                )
            }

            $analysis = Get-FailureAnalysis -TestResult $mockResult

            @($analysis.ByFile[$sharedFile]).Count | Should -Be 2
            @($analysis.ByFile['tests/unit/other.tests.ps1']).Count | Should -Be 1
        }

        It 'Groups failures by test category derived from tags' {
            $mockResult = @{
                FailedTests = @(
                    (New-MockFailure -Name 'Perf case' -File 'tests/performance/sample-performance.tests.ps1' -Message 'Slow' -Tags @('Performance'))
                    (New-MockFailure -Name 'Unit case' -File 'tests/unit/sample.tests.ps1' -Message 'Broken' -Tags @('Unit'))
                )
            }

            $analysis = Get-FailureAnalysis -TestResult $mockResult

            @($analysis.ByCategory['Performance']).Count | Should -Be 1
            @($analysis.ByCategory['Unit']).Count | Should -Be 1
        }

        It 'Captures test names in MostCommonErrors entries' {
            $mockResult = @{
                FailedTests = @(
                    (New-MockFailure -Name 'Alpha failure' -File 'tests/unit/a.tests.ps1' -Message 'Shared')
                    (New-MockFailure -Name 'Beta failure' -File 'tests/unit/b.tests.ps1' -Message 'Shared')
                )
            }

            $analysis = Get-FailureAnalysis -TestResult $mockResult
            $entry = $analysis.MostCommonErrors | Where-Object { $_.ErrorMessage -eq 'Shared' } | Select-Object -First 1

            $entry.Count | Should -Be 2
            @($entry.Tests).Count | Should -Be 2
        }
    }
}
