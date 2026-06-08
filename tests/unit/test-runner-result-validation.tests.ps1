<#
tests/unit/test-runner-result-validation.tests.ps1

.SYNOPSIS
    Unit tests for TestResultValidation module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestResultValidation.psm1') -Force -Global

    function script:New-ValidTestResult {
        param(
            [int]$Passed = 9,
            [int]$Failed = 1,
            [int]$Skipped = 0,
            [double]$DurationSeconds = 1.5
        )

        return [pscustomobject]@{
            TotalCount         = $Passed + $Failed + $Skipped
            PassedCount        = $Passed
            FailedCount        = $Failed
            SkippedCount       = $Skipped
            InconclusiveCount  = 0
            NotRunCount        = 0
            Time               = [TimeSpan]::FromSeconds($DurationSeconds)
        }
    }
}

Describe 'TestResultValidation Module' {
    Context 'Test-TestResultIntegrity' {
        It 'Rejects null test results' {
            $validation = Test-TestResultIntegrity -TestResult $null

            $validation.IsValid | Should -Be $false
            $validation.Issues | Should -Contain 'TestResult is null'
        }

        It 'Accepts consistent test counts' {
            $result = New-ValidTestResult
            $validation = Test-TestResultIntegrity -TestResult $result -ExpectedTests 10

            $validation.IsValid | Should -Be $true
            $validation.Issues.Count | Should -Be 0
        }

        It 'Flags inconsistent test counts' {
            $result = New-ValidTestResult
            $result.PassedCount = 20

            $validation = Test-TestResultIntegrity -TestResult $result

            $validation.IsValid | Should -Be $false
            ($validation.Issues -join ' ') | Should -Match 'inconsistent'
        }

        It 'Flags negative duration' {
            $result = New-ValidTestResult -DurationSeconds -1
            $validation = Test-TestResultIntegrity -TestResult $result

            $validation.IsValid | Should -Be $false
            $validation.Issues | Should -Contain 'Negative test duration detected'
        }

        It 'Applies custom validation rules' {
            $result = New-ValidTestResult
            $rules = @{
                RequireZeroFailures = {
                    param($TestResult)
                    if ($TestResult.FailedCount -eq 0) {
                        return @{ Passed = $true }
                    }

                    return @{
                        Passed   = $false
                        Severity = 'Error'
                        Message  = 'Failures detected'
                    }
                }
            }

            $validation = Test-TestResultIntegrity -TestResult $result -ValidationRules $rules

            $validation.IsValid | Should -Be $false
            ($validation.Issues -join ' ') | Should -Match 'RequireZeroFailures'
        }

        It 'Recommends review when failure rate is high' {
            $result = New-ValidTestResult -Passed 5 -Failed 5
            $validation = Test-TestResultIntegrity -TestResult $result

            $validation.Recommendations | Should -Contain 'High failure rate detected - review test stability'
        }

        It 'Recommends review when skip rate is high' {
            $result = New-ValidTestResult -Passed 3 -Failed 0 -Skipped 7
            $validation = Test-TestResultIntegrity -TestResult $result

            $validation.Recommendations | Should -Contain 'High skip rate detected - review test conditions'
        }
    }
}
