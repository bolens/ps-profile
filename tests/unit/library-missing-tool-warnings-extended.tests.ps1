<#
tests/unit/library-missing-tool-warnings-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for missing tool warning collection and suppression.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Platform.psm1') -DisableNameChecking -Force

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'MissingToolWarnings.ps1')
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_SUPPRESS_TOOL_WARNINGS -ErrorAction SilentlyContinue
}

Describe 'MissingToolWarnings extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PROFILE_SUPPRESS_TOOL_WARNINGS -ErrorAction SilentlyContinue
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    Context 'Write-MissingToolWarning' {
        It 'Suppresses warnings when PS_PROFILE_SUPPRESS_TOOL_WARNINGS is enabled' {
            $env:PS_PROFILE_SUPPRESS_TOOL_WARNINGS = '1'

            Write-MissingToolWarning -Tool 'suppressed-tool' -InstallHint 'Install manually'

            $global:CollectedMissingToolWarnings.Count | Should -Be 0
            $global:MissingToolWarnings.ContainsKey('suppressed-tool') | Should -Be $false
        }

        It 'Collects install hints for batch display' {
            Write-MissingToolWarning -Tool 'batch-tool' -InstallHint 'Install with: scoop install batch-tool'

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'batch-tool'
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'scoop install batch-tool'
        }

        It 'Dedupes repeated warnings unless Force is specified' {
            Write-MissingToolWarning -Tool 'dedupe-tool' -InstallHint 'first'
            Write-MissingToolWarning -Tool 'dedupe-tool' -InstallHint 'second'

            $global:CollectedMissingToolWarnings.Count | Should -Be 1

            Write-MissingToolWarning -Tool 'dedupe-tool' -InstallHint 'forced' -Force
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Be 'forced'
        }
    }

    Context 'Test-ToolAvailableOnPlatform' {
        It 'Treats unknown tools as cross-platform' {
            Test-ToolAvailableOnPlatform -Tool 'custom-cli-tool' | Should -Be $true
        }

        It 'Suppresses Windows-only tools on Linux hosts' {
            if ((Get-Platform).IsLinux) {
                Test-ToolAvailableOnPlatform -Tool 'choco' | Should -Be $false
            }
            else {
                Set-ItResult -Inconclusive -Because 'This assertion targets Linux hosts'
            }
        }
    }

    Context 'Clear-MissingToolWarnings' {
        It 'Removes only the requested tool entries' {
            Write-MissingToolWarning -Tool 'keep-tool' -InstallHint 'keep'
            Write-MissingToolWarning -Tool 'clear-tool' -InstallHint 'clear'

            Clear-MissingToolWarnings -Tool @('clear-tool') | Should -Be $true

            $global:MissingToolWarnings.ContainsKey('clear-tool') | Should -Be $false
            $global:MissingToolWarnings.ContainsKey('keep-tool') | Should -Be $true
        }
    }
}
