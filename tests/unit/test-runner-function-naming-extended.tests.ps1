<#
tests/unit/test-runner-function-naming-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FunctionNamingValidator parsing edge cases.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'FunctionNamingValidator.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'FunctionNamingExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FunctionNamingValidator extended scenarios' {
    Context 'Get-FunctionParts' {
        It 'Parses compound nouns after the verb prefix' {
            $parts = Get-FunctionParts -FunctionName 'Get-ExampleThing'

            $parts.IsValidFormat | Should -Be $true
            $parts.Verb | Should -Be 'Get'
            $parts.Noun | Should -Be 'ExampleThing'
        }

        It 'Rejects names with multiple hyphens' {
            $parts = Get-FunctionParts -FunctionName 'Get-Example-Thing'

            $parts.IsValidFormat | Should -Be $false
        }

        It 'Rejects names without a verb-noun separator' {
            $parts = Get-FunctionParts -FunctionName 'BadFunctionName'

            $parts.IsValidFormat | Should -Be $false
        }
    }

    Context 'Test-ApprovedVerb' {
        It 'Accepts common PowerShell approved verbs' {
            Test-ApprovedVerb -Verb 'Convert' | Should -Be $true
            Test-ApprovedVerb -Verb 'Register' | Should -Be $true
        }

        It 'Rejects unknown verb tokens' {
            Test-ApprovedVerb -Verb 'TotallyFakeVerb' | Should -Be $false
        }
    }

    Context 'Test-UsesAgentModeFunction' {
        It 'Returns false for missing source files' {
            $missing = Join-Path $script:TempDir 'missing-file.ps1'

            Test-UsesAgentModeFunction -FilePath $missing -FunctionName 'Get-MissingSample' | Should -Be $false
        }
    }
}
