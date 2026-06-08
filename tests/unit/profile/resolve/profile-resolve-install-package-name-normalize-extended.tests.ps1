<#
tests/unit/profile-resolve-install-package-name-normalize-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Resolve-InstallPackageName normalization behavior.
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

Describe 'Resolve-InstallPackageName normalization extended scenarios' {
    Context 'Resolve-InstallPackageName' {
        It 'Returns the original tool name when no alias mapping exists' {
            Resolve-InstallPackageName -ToolName 'custom-unmapped-tool' |
                Should -Be 'custom-unmapped-tool'
        }

        It 'Trims and lowercases tool names before alias lookup' {
            Resolve-InstallPackageName -ToolName '  RG  ' | Should -Be 'ripgrep'
            Resolve-InstallPackageName -ToolName ' HTTP ' | Should -Be 'httpie'
        }

        It 'Maps editor and emulator nightly aliases' {
            Resolve-InstallPackageName -ToolName 'neovim-nightly' | Should -Be 'neovim'
            Resolve-InstallPackageName -ToolName 'retroarch-nightly' | Should -Be 'retroarch'
        }

        It 'Maps infrastructure and database dump aliases' {
            Resolve-InstallPackageName -ToolName 'pg_dump' | Should -Be 'postgresql'
            Resolve-InstallPackageName -ToolName 'mongoexport' | Should -Be 'mongodb-database-tools'
        }

        It 'Maps LaTeX engine aliases to miktex' {
            Resolve-InstallPackageName -ToolName 'xelatex' | Should -Be 'miktex'
            Resolve-InstallPackageName -ToolName 'luatex' | Should -Be 'miktex'
        }
    }
}
