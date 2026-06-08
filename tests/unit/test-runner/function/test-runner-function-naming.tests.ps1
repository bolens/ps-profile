<#
tests/unit/test-runner-function-naming.tests.ps1

.SYNOPSIS
    Unit tests for FunctionNamingValidator module.
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
    Import-Module (Join-Path $modulePath 'FunctionNamingValidator.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'FunctionNamingTests'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FunctionNamingValidator Module' {
    Context 'Test-ApprovedVerb' {
        It 'Accepts standard approved verbs' {
            Test-ApprovedVerb -Verb 'Get' | Should -Be $true
            Test-ApprovedVerb -Verb 'Set' | Should -Be $true
            Test-ApprovedVerb -Verb 'Invoke' | Should -Be $true
        }

        It 'Rejects invented verbs' {
            Test-ApprovedVerb -Verb 'NotARealVerbXyz' | Should -Be $false
        }
    }

    Context 'Get-FunctionParts' {
        It 'Parses valid Verb-Noun function names' {
            $parts = Get-FunctionParts -FunctionName 'Get-ExampleThing'
            $parts.IsValidFormat | Should -Be $true
            $parts.Verb | Should -Be 'Get'
            $parts.Noun | Should -Be 'ExampleThing'
        }

        It 'Returns invalid format for malformed names' {
            $parts = Get-FunctionParts -FunctionName 'BadFunctionName'
            $parts.IsValidFormat | Should -Be $false
            $parts.Verb | Should -BeNullOrEmpty
        }
    }

    Context 'Test-UsesAgentModeFunction' {
        It 'Detects Set-AgentModeFunction registration' {
            $file = Join-Path $script:TempDir 'agent-mode.ps1'
            Set-Content -LiteralPath $file -Value @"
Set-AgentModeFunction -Name 'Get-AgentSample' -Body { 'ok' }
"@ -Encoding UTF8

            Test-UsesAgentModeFunction -FilePath $file -FunctionName 'Get-AgentSample' | Should -Be $true
        }

        It 'Detects guarded function definitions' {
            $file = Join-Path $script:TempDir 'guarded.ps1'
            Set-Content -LiteralPath $file -Value @"
if (-not (Test-Path Function:Get-GuardedSample)) {
    function Get-GuardedSample { 'ok' }
}
"@ -Encoding UTF8

            Test-UsesAgentModeFunction -FilePath $file -FunctionName 'Get-GuardedSample' | Should -Be $true
        }

        It 'Flags direct function keyword definitions' {
            $file = Join-Path $script:TempDir 'direct.ps1'
            Set-Content -LiteralPath $file -Value @"
function Get-DirectSample {
    'ok'
}
"@ -Encoding UTF8

            Test-UsesAgentModeFunction -FilePath $file -FunctionName 'Get-DirectSample' | Should -Be $false
        }
    }

    Context 'Test-IsBootstrapFunction' {
        It 'Identifies bootstrap infrastructure functions' {
            $bootstrapPath = Join-Path $script:TestRepoRoot 'profile.d/00-bootstrap.ps1'
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                Set-ItResult -Skipped -Because '00-bootstrap.ps1 not found'
                return
            }

            Test-IsBootstrapFunction -FilePath $bootstrapPath -FunctionName 'Set-AgentModeFunction' | Should -Be $true
        }

        It 'Returns false for non-bootstrap files' {
            $otherPath = Join-Path $script:TestRepoRoot 'profile.d/05-utilities.ps1'
            if (-not (Test-Path -LiteralPath $otherPath)) {
                Set-ItResult -Skipped -Because '05-utilities.ps1 not found'
                return
            }

            Test-IsBootstrapFunction -FilePath $otherPath -FunctionName 'Set-AgentModeFunction' | Should -Be $false
        }
    }
}
