<#
tests/unit/library-path-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PathResolution Get-RepoRoot edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'path' 'PathResolution.psm1') -DisableNameChecking -ErrorAction Stop

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
}

AfterAll {
    Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
}

Describe 'Path module extended scenarios' {
    Context 'Get-RepoRoot' {
        It 'Resolves repository root from scripts/lib module paths' {
            $modulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
            Get-RepoRoot -ScriptPath $modulePath | Should -Be $script:RepoRoot
        }

        It 'Resolves repository root from scripts/checks paths under test-artifacts' {
            $checkScript = Get-TestScriptPath -RelativePath 'scripts/checks/path-probe.ps1' -StartPath $PSScriptRoot
            Get-RepoRoot -ScriptPath $checkScript | Should -Be $script:RepoRoot
        }

        It 'Returns the same root for scripts/utils and scripts/lib callers' {
            $utilityScript = Get-TestPath -RelativePath 'scripts\utils\code-quality\run-pester.ps1' -StartPath $PSScriptRoot -EnsureExists
            $libraryModule = Get-TestPath -RelativePath 'scripts\lib\core\Logging.psm1' -StartPath $PSScriptRoot -EnsureExists

            Get-RepoRoot -ScriptPath $utilityScript | Should -Be (Get-RepoRoot -ScriptPath $libraryModule)
        }

        It 'Returns a root containing the scripts directory' {
            $utilityScript = Get-TestPath -RelativePath 'scripts\utils\code-quality\run-pester.ps1' -StartPath $PSScriptRoot -EnsureExists
            $repoRoot = Get-RepoRoot -ScriptPath $utilityScript

            Test-Path -LiteralPath (Join-Path $repoRoot 'scripts') | Should -Be $true
        }

        It 'Matches Get-TestRepoRoot for standard test file locations' {
            $testScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/test.ps1' -StartPath $PSScriptRoot
            Get-RepoRoot -ScriptPath $testScriptPath | Should -Be $script:RepoRoot
        }
    }
}
