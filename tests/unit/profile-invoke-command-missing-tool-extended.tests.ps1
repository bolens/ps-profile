<#
tests/unit/profile-invoke-command-missing-tool-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-CommandMissingToolWarning composition.
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

Describe 'Invoke-CommandMissingToolWarning extended scenarios' {
    BeforeEach {
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    Context 'Invoke-CommandMissingToolWarning' {
        It 'Uses the Tool parameter as the displayed warning name' {
            Invoke-CommandMissingToolWarning `
                -CommandName 'pnpm' `
                -Tool 'pnpm package manager'

            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'pnpm package manager'
        }

        It 'Infers node-package hints for npm commands' {
            Invoke-CommandMissingToolWarning -CommandName 'npm'

            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'npm'
        }

        It 'Forwards DefaultInstallCommand when hint resolvers are unavailable' {
            $originalPlatformHint = Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue
            $originalPreferenceHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue

            try {
                Invoke-CommandMissingToolWarning `
                    -CommandName 'custom-cli' `
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

        It 'Falls back to Write-MissingToolWarning when Invoke-MissingToolWarning is unavailable' {
            $originalInvoke = Get-Command Invoke-MissingToolWarning -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-MissingToolWarning -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Invoke-MissingToolWarning -Force -ErrorAction SilentlyContinue

            try {
                Invoke-CommandMissingToolWarning `
                    -CommandName 'missing-runner' `
                    -DefaultInstallCommand 'install missing-runner manually'

                $global:CollectedMissingToolWarnings[0].InstallHint |
                    Should -Match 'install missing-runner manually'
            }
            finally {
                if ($null -ne $originalInvoke) {
                    Set-Item -Path Function:\global:Invoke-MissingToolWarning -Value $originalInvoke.ScriptBlock -Force
                }
            }
        }

        It 'Classifies pip commands as python-package tool types' {
            Invoke-CommandMissingToolWarning -CommandName 'pip'

            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'pip'
        }
    }
}
