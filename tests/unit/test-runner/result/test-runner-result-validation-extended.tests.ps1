<#
tests/unit/test-runner-result-validation-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestResultValidation custom rules and warnings.
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
    Import-Module (Join-Path $modulePath 'TestResultValidation.psm1') -Force -Global

    function script:New-ValidTestResult {
        param(
            [int]$Passed = 9,
            [int]$Failed = 1,
            [int]$Skipped = 0,
            [double]$DurationSeconds = 1.5
        )

        return [pscustomobject]@{
            TotalCount        = $Passed + $Failed + $Skipped
            PassedCount       = $Passed
            FailedCount       = $Failed
            SkippedCount      = $Skipped
            InconclusiveCount = 0
            NotRunCount       = 0
            Time              = [TimeSpan]::FromSeconds($DurationSeconds)
        }
    }
}

Describe 'TestResultValidation extended scenarios' {
    Context 'Test-TestResultIntegrity' {
        It 'Records a warning when expected test count differs' {
            $result = New-ValidTestResult -Passed 8 -Failed 2
            $validation = Test-TestResultIntegrity -TestResult $result -ExpectedTests 15

            $validation.IsValid | Should -Be $true
            @($validation.Warnings | Where-Object { $_ -match 'Expected 15 tests' }).Count | Should -Be 1
        }

        It 'Treats warning-severity custom rules as non-fatal' {
            $result = New-ValidTestResult -Passed 10 -Failed 0
            $rules = @{
                PreferFewSkips = {
                    param($TestResult)
                    return @{
                        Passed   = $false
                        Severity = 'Warning'
                        Message  = 'Skipped tests present'
                    }
                }
            }

            $validation = Test-TestResultIntegrity -TestResult $result -ValidationRules $rules

            $validation.IsValid | Should -Be $true
            ($validation.Warnings -join ' ') | Should -Match 'PreferFewSkips'
        }

        It 'Records warnings when custom validation rules throw' {
            $result = New-ValidTestResult
            $rules = @{
                BrokenRule = {
                    throw 'rule exploded'
                }
            }

            $validation = Test-TestResultIntegrity -TestResult $result -ValidationRules $rules

            $validation.IsValid | Should -Be $true
            ($validation.Warnings -join ' ') | Should -Match 'BrokenRule'
        }

        It 'Does not recommend review for moderate failure rates' {
            $result = New-ValidTestResult -Passed 9 -Failed 1
            $validation = Test-TestResultIntegrity -TestResult $result

            @($validation.Recommendations | Where-Object { $_ -match 'High failure rate' }).Count | Should -Be 0
        }

        It 'Does not recommend review for moderate skip rates' {
            $result = New-ValidTestResult -Passed 8 -Failed 0 -Skipped 2
            $validation = Test-TestResultIntegrity -TestResult $result

            @($validation.Recommendations | Where-Object { $_ -match 'High skip rate' }).Count | Should -Be 0
        }
    }
}
