<#
tests/unit/test-runner-test-failure-analysis-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-FailureAnalysis ranking and grouping.
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
            [string[]]$Tags = @('Unit')
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

Describe 'TestFailureAnalysis extended scenarios' {
    Context 'Get-FailureAnalysis ranking' {
        It 'Ranks MostCommonErrors by occurrence count' {
            $mockResult = @{
                FailedTests = @(
                    (New-MockFailure -Name 'A1' -File 'tests/unit/a.tests.ps1' -Message 'Shared error')
                    (New-MockFailure -Name 'A2' -File 'tests/unit/a.tests.ps1' -Message 'Shared error')
                    (New-MockFailure -Name 'B1' -File 'tests/unit/b.tests.ps1' -Message 'Unique error')
                )
            }

            $analysis = Get-FailureAnalysis -TestResult $mockResult

            @($analysis.MostCommonErrors).Count | Should -BeGreaterThan 0
            $analysis.MostCommonErrors[0].ErrorMessage | Should -Be 'Shared error'
            $analysis.MostCommonErrors[0].Count | Should -Be 2
        }

        It 'Groups repeated failures under the same error message key' {
            $mockResult = @{
                FailedTests = @(
                    (New-MockFailure -Name 'One' -File 'tests/unit/x.tests.ps1' -Message 'Timeout expired')
                    (New-MockFailure -Name 'Two' -File 'tests/unit/y.tests.ps1' -Message 'Timeout expired')
                )
            }

            $analysis = Get-FailureAnalysis -TestResult $mockResult

            @($analysis.ByErrorMessage['Timeout expired']).Count | Should -Be 2
        }

        It 'Limits MostCommonErrors to five entries' {
            $failures = 1..7 | ForEach-Object {
                New-MockFailure -Name "Failure $_" -File "tests/unit/file-$_.tests.ps1" -Message "Error $_"
            }
            $analysis = Get-FailureAnalysis -TestResult @{ FailedTests = $failures }

            @($analysis.MostCommonErrors).Count | Should -Be 5
        }
    }
}
