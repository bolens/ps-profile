<#
tests/unit/profile-install-package-resolve-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for install package name and tool type resolution.
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

Describe 'Install package resolution extended scenarios' {
    Context 'Resolve-InstallPackageName' {
        It 'Maps ripgrep shorthand to the ripgrep package name' {
            Resolve-InstallPackageName -ToolName 'rg' | Should -Be 'ripgrep'
        }

        It 'Maps http shorthand to the httpie package name' {
            Resolve-InstallPackageName -ToolName 'http' | Should -Be 'httpie'
        }

        It 'Normalizes case before applying alias lookup' {
            Resolve-InstallPackageName -ToolName '  RG  ' | Should -Be 'ripgrep'
        }

        It 'Returns the original tool name when no alias exists' {
            Resolve-InstallPackageName -ToolName 'custom-tool-xyz' | Should -Be 'custom-tool-xyz'
        }
    }

    Context 'Resolve-CommandInstallToolType' {
        It 'Classifies node package managers correctly' {
            Resolve-CommandInstallToolType -CommandName 'pnpm' | Should -Be 'node-package'
            Resolve-CommandInstallToolType -CommandName 'npm' | Should -Be 'node-package'
        }

        It 'Classifies python package managers correctly' {
            Resolve-CommandInstallToolType -CommandName 'uv' | Should -Be 'python-package'
            Resolve-CommandInstallToolType -CommandName 'pip3' | Should -Be 'python-package'
        }

        It 'Defaults unknown commands to the generic tool type' {
            Resolve-CommandInstallToolType -CommandName 'totally-unknown-command' | Should -Be 'generic'
        }
    }
}
