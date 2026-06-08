<#
tests/unit/library-platform-specific-tools-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for platform-specific tool availability mapping.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Platform.psm1') -DisableNameChecking -Force

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'MissingToolWarnings.ps1')
}

Describe 'Platform-specific tools extended scenarios' {
    Context 'Get-PlatformSpecificTools' {
        It 'Includes Windows-specific package managers' {
            $tools = Get-PlatformSpecificTools

            $tools['winget'] | Should -Contain 'Windows'
            $tools['choco'] | Should -Contain 'Windows'
        }

        It 'Includes Linux-specific package managers' {
            $tools = Get-PlatformSpecificTools

            $tools['apt'] | Should -Contain 'Linux'
            $tools['pacman'] | Should -Contain 'Linux'
        }

        It 'Includes macOS homebrew mapping' {
            $tools = Get-PlatformSpecificTools

            $tools['brew'] | Should -Contain 'macOS'
            $tools['homebrew'] | Should -Contain 'macOS'
        }

        It 'Maps asdf to Unix-like platforms' {
            $tools = Get-PlatformSpecificTools

            $tools['asdf'] | Should -Contain 'Linux'
            $tools['asdf'] | Should -Contain 'macOS'
        }
    }

    Context 'Test-ToolAvailableOnPlatform' {
        It 'Suppresses winget warnings on Linux hosts' {
            if ((Get-Platform).IsLinux) {
                Test-ToolAvailableOnPlatform -Tool 'winget' | Should -Be $false
            }
            else {
                Set-ItResult -Inconclusive -Because 'This assertion targets Linux hosts'
            }
        }

        It 'Allows homebrew warnings on macOS hosts' {
            if ((Get-Platform).IsMacOS) {
                Test-ToolAvailableOnPlatform -Tool 'brew' | Should -Be $true
            }
            else {
                Set-ItResult -Inconclusive -Because 'This assertion targets macOS hosts'
            }
        }
    }
}
