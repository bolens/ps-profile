<#
tests/unit/test-runner-helpers.tests.ps1

.SYNOPSIS
    Unit tests for test runner helper and exception modules.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestRunnerHelpers.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'ExceptionHandler.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
    $script:ExceptionsFile = Join-Path $script:TestRepoRoot 'docs/guides/FUNCTION_NAMING_EXCEPTIONS.md'
}

Describe 'TestRunnerHelpers Module' {
    Context 'Invoke-TestDryRun' {
        It 'Lists discovered test files without executing them' {
            $tempDir = New-TestTempDirectory -Prefix 'DryRunTests'
            $testFile = Join-Path $tempDir 'sample.tests.ps1'
            Set-Content -LiteralPath $testFile -Value 'Describe sample {}' -Encoding UTF8

            try {
                Register-TestWriteHostCapture
                Invoke-TestDryRun -Config $null -TestPaths @($tempDir) | Out-Null

                Get-TestWriteHostOutputString | Should -Match ([regex]::Escape($testFile))
            }
            finally {
                Restore-TestTerminalStubs
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Reports a single test file path' {
            $testFile = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'
            if (-not (Test-Path -LiteralPath $testFile)) {
                Set-ItResult -Skipped -Because 'library-common.tests.ps1 not found'
                return
            }

            Register-TestWriteHostCapture
            try {
                Invoke-TestDryRun -Config $null -TestPaths @($testFile) | Out-Null
                Get-TestWriteHostOutputString | Should -Match 'library-common\.tests\.ps1'
            }
            finally {
                Restore-TestTerminalStubs
            }
        }
    }
}

Describe 'ExceptionHandler Module' {
    Context 'Get-NamingExceptions' {
        It 'Parses documented function exceptions' {
            if (-not (Test-Path -LiteralPath $script:ExceptionsFile)) {
                Set-ItResult -Skipped -Because 'FUNCTION_NAMING_EXCEPTIONS.md not found'
                return
            }

            $result = Get-NamingExceptions -ExceptionsFile $script:ExceptionsFile
            $result.Exceptions.ContainsKey('Set-AgentModeFunction') | Should -Be $true
            $result.ExceptionVerbs | Should -Contain 'Ensure'
        }

        It 'Returns empty exceptions for missing files' {
            $result = Get-NamingExceptions -ExceptionsFile (Join-Path $script:TestRepoRoot 'missing-exceptions-file.md')
            $result.Exceptions.Count | Should -Be 0
            $result.ExceptionVerbs.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Test-IsException' {
        It 'Treats documented exceptions as exempt' {
            $exceptions = Get-NamingExceptions -ExceptionsFile $script:ExceptionsFile
            Test-IsException `
                -FunctionName 'Set-AgentModeFunction' `
                -Verb 'Set' `
                -FilePath (Join-Path $script:TestRepoRoot 'profile.d/00-bootstrap.ps1') `
                -Exceptions $exceptions.Exceptions `
                -ExceptionVerbs $exceptions.ExceptionVerbs | Should -Be $true
        }

        It 'Treats test files as exempt' {
            $exceptions = Get-NamingExceptions -ExceptionsFile $script:ExceptionsFile
            Test-IsException `
                -FunctionName 'Get-CustomThing' `
                -Verb 'Get' `
                -FilePath (Join-Path $script:TestRepoRoot 'tests/unit/sample.tests.ps1') `
                -Exceptions $exceptions.Exceptions `
                -ExceptionVerbs $exceptions.ExceptionVerbs | Should -Be $true
        }

        It 'Returns false for normal profile functions not in the exception list' {
            $exceptions = Get-NamingExceptions -ExceptionsFile $script:ExceptionsFile
            Test-IsException `
                -FunctionName 'Get-ZzzMadeUpFunction' `
                -Verb 'Get' `
                -FilePath (Join-Path $script:TestRepoRoot 'profile.d/05-utilities.ps1') `
                -Exceptions $exceptions.Exceptions `
                -ExceptionVerbs $exceptions.ExceptionVerbs | Should -Be $false
        }
    }
}
