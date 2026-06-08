<#
tests/unit/test-runner-exception-handler-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ExceptionHandler naming exception helpers.
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
    Import-Module (Join-Path $modulePath 'ExceptionHandler.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ExceptionHandlerExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ExceptionHandler extended scenarios' {
    Context 'Get-NamingExceptions' {
        It 'Parses function names from markdown exception lists' {
            $exceptionsFile = Join-Path $script:TempDir 'exceptions.md'
            @'
# Exceptions

- `Set-AgentModeFunction`
- `Ensure-FileConversion`
- Ensure-PlainName
'@ | Set-Content -LiteralPath $exceptionsFile -Encoding UTF8

            $result = Get-NamingExceptions -ExceptionsFile $exceptionsFile

            $result.Exceptions.ContainsKey('Set-AgentModeFunction') | Should -Be $true
            $result.Exceptions.ContainsKey('Ensure-FileConversion') | Should -Be $true
            $result.Exceptions.ContainsKey('Ensure-PlainName') | Should -Be $true
            @($result.ExceptionVerbs).Count | Should -BeGreaterThan 0
        }

        It 'Returns empty exception maps for missing files' {
            $missing = Join-Path $script:TempDir 'missing-exceptions.md'
            $result = Get-NamingExceptions -ExceptionsFile $missing

            @($result.Exceptions.Keys).Count | Should -Be 0
            @($result.ExceptionVerbs).Count | Should -BeGreaterThan 0
        }
    }

    Context 'Test-IsException' {
        It 'Treats listed function names as exceptions' {
            $exceptions = @{ 'Get-SpecialSample' = $true }

            Test-IsException -FunctionName 'Get-SpecialSample' -Verb 'Get' `
                -FilePath (Join-Path $script:TempDir 'sample.ps1') `
                -Exceptions $exceptions -ExceptionVerbs @('Ensure') |
                Should -Be $true
        }

        It 'Treats exception verbs as exempt' {
            Test-IsException -FunctionName 'Ensure-ToolSample' -Verb 'Ensure' `
                -FilePath (Join-Path $script:TempDir 'sample.ps1') `
                -Exceptions @{} -ExceptionVerbs @('Ensure', 'Reload') |
                Should -Be $true
        }

        It 'Treats test files as exempt regardless of verb' {
            $testFile = Join-Path $script:TempDir 'tests/unit/sample.tests.ps1'

            Test-IsException -FunctionName 'NotApproved-Sample' -Verb 'NotApproved' `
                -FilePath $testFile -Exceptions @{} -ExceptionVerbs @('NotUsedVerbXyz') |
                Should -Be $true
        }

        It 'Treats bootstrap functions in 00-bootstrap.ps1 as exempt' {
            $bootstrapFile = Join-Path $script:TempDir 'profile.d/00-bootstrap.ps1'

            Test-IsException -FunctionName 'Set-AgentModeFunction' -Verb 'Set' `
                -FilePath $bootstrapFile -Exceptions @{} -ExceptionVerbs @('NotUsedVerbXyz') |
                Should -Be $true
        }
    }
}
