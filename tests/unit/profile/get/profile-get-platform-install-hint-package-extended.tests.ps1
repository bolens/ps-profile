<#
tests/unit/profile-get-platform-install-hint-package-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-PlatformInstallHint package name overrides.
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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'CommandCache.ps1'
            'AssumedCommands.ps1'
            'MissingToolWarnings.ps1'
            'ToolInstallRegistry.ps1'
            'InstallHintResolver.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'Get-PlatformInstallHint package override extended scenarios' {
    Context 'Get-PlatformInstallHint' {
        It 'Uses InstallPackageName instead of Resolve-InstallPackageName mappings' {
            $hint = Get-PlatformInstallHint `
                -ToolName 'rg' `
                -InstallPackageName 'ripgrep-custom'

            $hint | Should -Match 'ripgrep-custom'
        }

        It 'Forwards ToolType values to Get-PreferenceAwareInstallHint' {
            $hint = Get-PlatformInstallHint -ToolName 'typescript' -ToolType 'node-package'
            $hint | Should -Match 'typescript'
        }

        It 'Falls back to scoop install when preference hints are unavailable' {
            $originalPreferenceHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue

                        Get-PlatformInstallHint -ToolName 'custom-tool' |
                Should -Be 'Install with: scoop install custom-tool'
        }
        finally {
            if ($null -ne $originalPreferenceHint) {
                Set-Item -Path Function:\global:Get-PreferenceAwareInstallHint -Value $originalPreferenceHint.ScriptBlock -Force
            }
        }

        It 'Resolves mapped package names when InstallPackageName is omitted' {
            $hint = Get-PlatformInstallHint -ToolName 'http'
            $hint | Should -Match 'httpie'
        }

        It 'Prefixes hints with Install with for generic tools' {
            $hint = Get-PlatformInstallHint -ToolName 'jq'
            $hint | Should -Match '^Install with:'
        }
    }
}
