<#
tests/unit/test-runner-validation-reporter-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ValidationReporter console output.
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
    Import-Module (Join-Path $modulePath 'ValidationReporter.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'ExceptionHandler.psm1') -Force -Global
}

Describe 'ValidationReporter extended scenarios' {
    Context 'Write-ValidationReport' {
        AfterEach {
            if (Get-Command Restore-TestTerminalStubs -ErrorAction SilentlyContinue) {
                Restore-TestTerminalStubs
            }
        }

        It 'Prints a success summary when no issues are found' {
            $results = [pscustomobject]@{
                TotalFunctions                     = 2
                FunctionsWithApprovedVerbs         = 2
                FunctionsWithUnapprovedVerbs       = 0
                FunctionsWithInvalidFormat         = 0
                ProfileDFunctionsNotUsingAgentMode = 0
                ExceptionsCount                    = 0
                Issues                             = @()
            }

            Register-TestWriteHostCapture
            Write-ValidationReport -Results $results

            $output = Get-TestWriteHostOutputString
            $output | Should -Match 'Function Naming Validation Results'
            $output | Should -Match 'No issues found'
        }

        It 'Lists validation issues in output text' {
            $results = [pscustomobject]@{
                TotalFunctions                     = 1
                FunctionsWithApprovedVerbs         = 0
                FunctionsWithUnapprovedVerbs       = 1
                FunctionsWithInvalidFormat         = 0
                ProfileDFunctionsNotUsingAgentMode = 0
                ExceptionsCount                    = 0
                Issues                             = @(
                    [pscustomobject]@{
                        FunctionName = 'BadVerb-Thing'
                        FilePath     = 'profile.d/sample.ps1'
                        Issues       = 'Unapproved verb: BadVerb'
                    }
                )
            }

            Register-TestWriteHostCapture
            Write-ValidationReport -Results $results

            $output = Get-TestWriteHostOutputString
            $output | Should -Match 'Issues Found'
            $output | Should -Match 'BadVerb-Thing'
            $output | Should -Match 'Unapproved verb'
        }
    }

    Context 'Get-ValidationResults with exceptions' {
        It 'Excludes documented exception verbs from issue counts' {
            $functions = @(
                [pscustomobject]@{
                    Name                     = 'Ensure-SampleTool'
                    Verb                     = 'Ensure'
                    Noun                     = 'SampleTool'
                    IsValidFormat            = $true
                    HasApprovedVerb          = $false
                    FilePath                 = '/tmp/validation/ensure.ps1'
                    RelativePath             = 'ensure.ps1'
                    UsesSetAgentModeFunction = $false
                }
            )

            $results = Get-ValidationResults -Functions $functions -Exceptions @{} -ExceptionVerbs @('Ensure')

            $results.FunctionsWithUnapprovedVerbs | Should -Be 0
            $results.Issues.Count | Should -Be 0
        }
    }
}
