<#
tests/unit/profile-preference-aware-install-hints-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for preference-aware install hint edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:BootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'CommandCache.ps1'
            'AssumedCommands.ps1'
            'MissingToolWarnings.ps1'
            'ToolInstallRegistry.ps1'
            'InstallHintResolver.ps1'
        )) {
        . (Join-Path $script:BootstrapDir $bootstrapFile)
    }
}

Describe 'Preference-aware install hints extended scenarios' {
    BeforeEach {
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    AfterEach {
        Remove-Item Env:\PS_RUST_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PYTHON_RUNTIME -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    Context 'Get-PreferenceAwareInstallHint' {
        It 'Uses DefaultInstallCommand when tool-specific resolution is unavailable' {
            $hint = Get-PreferenceAwareInstallHint `
                -ToolName 'custom-tool-xyz' `
                -ToolType 'generic' `
                -DefaultInstallCommand 'scoop install custom-tool-xyz'

            $hint | Should -Be 'Install with: scoop install custom-tool-xyz'
        }

        It 'Respects PS_RUST_PACKAGE_MANAGER when generating rust tool hints' {
            $env:PS_RUST_PACKAGE_MANAGER = 'cargo'
            $hint = Get-PreferenceAwareInstallHint -ToolName 'cargo-watch' -ToolType 'rust-package'
            $hint | Should -Match 'Install with:'
            $hint | Should -Match 'cargo'
        }
    }

    Context 'Invoke-MissingToolWarning' {
        It 'Appends AdditionalHint text when it is not already present' {
            Invoke-MissingToolWarning `
                -ToolName 'ffmpeg' `
                -ToolType 'generic' `
                -AdditionalHint '(required for conversion)'

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].InstallHint |
                Should -Match 'required for conversion'
        }

        It 'Uses InstallPackageName overrides for registry lookups' {
            Invoke-MissingToolWarning `
                -ToolName 'rg' `
                -InstallPackageName 'ripgrep'

            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'ripgrep'
        }
    }

    Context 'Test-PreferenceAwareInstallPreferences extended validation' {
        It 'Detects invalid python runtime preferences' {
            $env:PS_PYTHON_RUNTIME = 'invalid-runtime'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'python-runtime'

            $result.Valid | Should -Be $false
            $result.Errors | Should -Match 'PS_PYTHON_RUNTIME'
        }

        It 'Records auto system package manager preference during all-mode validation' {
            Remove-Item Env:\PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'all'

            $result.Preferences['PS_SYSTEM_PACKAGE_MANAGER'] | Should -Be 'auto'
        }
    }
}
