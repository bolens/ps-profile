<#
tests/unit/profile-install-hint-platform-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for platform and container install hint helpers.
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

Describe 'InstallHintResolver platform extended scenarios' {
    BeforeEach {
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    Context 'Resolve-CommandInstallToolType' {
        It 'Classifies common package managers by command name' {
            Resolve-CommandInstallToolType -CommandName 'pnpm' | Should -Be 'node-package'
            Resolve-CommandInstallToolType -CommandName 'uv' | Should -Be 'python-package'
            Resolve-CommandInstallToolType -CommandName 'cargo' | Should -Be 'rust-package'
            Resolve-CommandInstallToolType -CommandName 'gradle' | Should -Be 'java-build-tool'
        }

        It 'Falls back to generic for unrecognized commands' {
            Resolve-CommandInstallToolType -CommandName 'custom-cli-tool' | Should -Be 'generic'
        }
    }

    Context 'Get-PlatformInstallHint' {
        It 'Uses InstallPackageName when it differs from ToolName' {
            $hint = Get-PlatformInstallHint -ToolName 'rg' -InstallPackageName 'ripgrep'
            $hint | Should -Match 'Install with:'
            $hint | Should -Match 'ripgrep'
        }

        It 'Respects explicit ToolType for language-specific tools' {
            $hint = Get-PlatformInstallHint -ToolName 'typescript' -ToolType 'node-package'
            $hint | Should -Match 'Install with:'
            $hint | Should -Match 'typescript'
        }
    }

    Context 'Container engine hints' {
        It 'Builds combined docker and podman install hints' {
            $hint = Get-ContainerEngineInstallHint
            $hint | Should -Match 'Install with:'
            $hint | Should -Match 'docker'
            $hint | Should -Match 'podman'
        }

        It 'Strips the Install with prefix from container installation commands' {
            $command = Get-ContainerInstallationCommand
            $command | Should -Not -Match '^Install with:'
            $command | Should -Match 'docker'
        }

        It 'Returns bare installation commands via Get-ToolInstallationCommand' {
            $command = Get-ToolInstallationCommand -ToolName 'jq'
            $command | Should -Not -Match '^Install with:'
            $command | Should -Match 'jq'
        }
    }

    Context 'Invoke-CommandMissingToolWarning' {
        It 'Collects warnings with inferred node-package tool type' {
            Invoke-CommandMissingToolWarning -CommandName 'pnpm'

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'pnpm'
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'Install'
        }
    }
}
