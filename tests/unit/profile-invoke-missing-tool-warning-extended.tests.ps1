<#
tests/unit/profile-invoke-missing-tool-warning-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-MissingToolWarning hint composition.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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

Describe 'Invoke-MissingToolWarning extended scenarios' {
    BeforeEach {
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    Context 'Invoke-MissingToolWarning' {
        It 'Uses the Tool parameter as the displayed warning name' {
            Invoke-MissingToolWarning -ToolName 'rg' -Tool 'ripgrep-cli'

            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'ripgrep-cli'
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'Install'
        }

        It 'Falls back to DefaultInstallCommand when hint resolvers are unavailable' {
            $originalPlatformHint = Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue
            $originalPreferenceHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue

            try {
                Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
                Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

                Invoke-MissingToolWarning `
                    -ToolName 'custom-cli' `
                    -DefaultInstallCommand 'scoop install custom-cli'

                $global:CollectedMissingToolWarnings[0].InstallHint |
                    Should -Be 'Install with: scoop install custom-cli'
            }
            finally {
                if ($null -ne $originalPlatformHint) {
                    Set-Item -Path Function:\global:Get-PlatformInstallHint -Value $originalPlatformHint.ScriptBlock -Force
                }
                if ($null -ne $originalPreferenceHint) {
                    Set-Item -Path Function:\global:Get-PreferenceAwareInstallHint -Value $originalPreferenceHint.ScriptBlock -Force
                }
            }
        }

        It 'Does not duplicate AdditionalHint text already present in the install hint' {
            Invoke-MissingToolWarning `
                -ToolName 'docker' `
                -AdditionalHint 'requires Docker'

            $hint = $global:CollectedMissingToolWarnings[0].InstallHint
            ([regex]::Matches($hint, 'requires Docker')).Count | Should -BeLessOrEqual 1
        }

        It 'Appends AdditionalHint when it is not already in the resolved hint' {
            Invoke-MissingToolWarning `
                -ToolName 'pandoc' `
                -AdditionalHint '(needed for export)'

            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'needed for export'
        }

        It 'Resolves hints using explicit ToolType values' {
            Invoke-MissingToolWarning -ToolName 'typescript' -ToolType 'node-package'

            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'typescript'
        }
    }
}
