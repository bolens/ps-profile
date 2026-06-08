<#
tests/unit/test-runner-helpers-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for test runner helper and exception modules.
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
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestRunnerHelpers.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'ExceptionHandler.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'TestRunnerHelpersExtended'
    $script:ExceptionsFile = Join-Path $script:TestRepoRoot 'docs/guides/FUNCTION_NAMING_EXCEPTIONS.md'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestRunnerHelpers extended scenarios' {
    Context 'Invoke-TestDryRun' {
        It 'Discovers multiple test files under a directory tree' {
            $tempDir = Join-Path $script:TempDir 'nested-dry-run'
            $nestedDir = Join-Path $tempDir 'nested'
            New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
            $rootFile = Join-Path $tempDir 'root.tests.ps1'
            $nestedFile = Join-Path $nestedDir 'nested.tests.ps1'
            Set-Content -LiteralPath $rootFile -Value 'Describe root {}' -Encoding UTF8
            Set-Content -LiteralPath $nestedFile -Value 'Describe nested {}' -Encoding UTF8

            Register-TestWriteHostCapture
            try {
                Invoke-TestDryRun -Config $null -TestPaths @($tempDir) | Out-Null
                $output = Get-TestWriteHostOutputString
                $output | Should -Match ([regex]::Escape('root.tests.ps1'))
                $output | Should -Match ([regex]::Escape('nested.tests.ps1'))
            }
            finally {
                Restore-TestTerminalStubs
            }
        }

        It 'Lists a single file path without executing tests' {
            $testFile = Join-Path $script:TempDir 'single.tests.ps1'
            Set-Content -LiteralPath $testFile -Value 'Describe single {}' -Encoding UTF8

            Register-TestWriteHostCapture
            try {
                Invoke-TestDryRun -Config $null -TestPaths @($testFile) | Out-Null
                Get-TestWriteHostOutputString | Should -Match ([regex]::Escape('single.tests.ps1'))
            }
            finally {
                Restore-TestTerminalStubs
            }
        }
    }
}

Describe 'ExceptionHandler extended scenarios' {
    Context 'Get-NamingExceptions' {
        It 'Parses backtick-wrapped function names from markdown lists' {
            $exceptionsFile = Join-Path $script:TempDir 'parsed-exceptions.md'
            @'
# Exceptions

- `Set-AgentModeFunction`
- `Ensure-FileConversion`
'@ | Set-Content -LiteralPath $exceptionsFile -Encoding UTF8

            $result = Get-NamingExceptions -ExceptionsFile $exceptionsFile
            $result.Exceptions.ContainsKey('Set-AgentModeFunction') | Should -Be $true
            $result.Exceptions.ContainsKey('Ensure-FileConversion') | Should -Be $true
        }

        It 'Returns empty exception maps for missing files' {
            $missing = Join-Path $script:TempDir 'missing-exceptions.md'
            $result = Get-NamingExceptions -ExceptionsFile $missing

            @($result.Exceptions.Keys).Count | Should -Be 0
            @($result.ExceptionVerbs).Count | Should -BeGreaterThan 0
        }
    }

    Context 'Test-IsException' {
        It 'Treats exception verbs as exempt' {
            Test-IsException -FunctionName 'Ensure-ToolSample' -Verb 'Ensure' `
                -FilePath (Join-Path $script:TempDir 'sample.ps1') `
                -Exceptions @{} -ExceptionVerbs @('Ensure', 'Reload') |
                Should -Be $true
        }

        It 'Treats bootstrap functions in 00-bootstrap.ps1 as exempt' {
            $bootstrapFile = Join-Path $script:TempDir 'profile.d/00-bootstrap.ps1'
            New-Item -ItemType Directory -Path (Split-Path $bootstrapFile) -Force | Out-Null

            Test-IsException -FunctionName 'Set-AgentModeFunction' -Verb 'Set' `
                -FilePath $bootstrapFile -Exceptions @{} -ExceptionVerbs @('NotUsedVerbXyz') |
                Should -Be $true
        }

        It 'Returns false for unlisted functions outside exempt paths' {
            if (-not (Test-Path -LiteralPath $script:ExceptionsFile)) {
                Set-ItResult -Skipped -Because 'FUNCTION_NAMING_EXCEPTIONS.md not found'
                return
            }

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
