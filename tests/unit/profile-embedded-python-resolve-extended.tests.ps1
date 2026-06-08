<#
tests/unit/profile-embedded-python-resolve-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Python embedded install hint resolution helpers.
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
            'EmbeddedInstallHints.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

AfterAll {
    Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
}

Describe 'Embedded Python install hint resolve extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    Context 'Resolve-PythonInstallHintMessage' {
        It 'Replaces __PYTHON_INSTALL_CMD__ placeholders in messages' {
            $resolved = Resolve-PythonInstallHintMessage `
                -Message 'Install deps: __PYTHON_INSTALL_CMD__' `
                -PackageNames @('numpy')

            $resolved | Should -Not -Match '__PYTHON_INSTALL_CMD__'
            $resolved | Should -Match 'numpy'
        }

        It 'Returns the original message when no placeholder token is present' {
            $message = 'No install step required'
            Resolve-PythonInstallHintMessage -Message $message -PackageNames @('pandas') | Should -Be $message
        }
    }

    Context 'global:Get-PythonPackageInstallRecommendation' {
        It 'Builds recommendations from the PackageName parameter' {
            $command = global:Get-PythonPackageInstallRecommendation -PackageName 'requests'
            $command | Should -Match 'requests'
        }

        It 'Combines multiple package names into one recommendation' {
            $command = global:Get-PythonPackageInstallRecommendation -PackageNames @('numpy', 'pandas')
            $command | Should -Match 'numpy'
            $command | Should -Match 'pandas'
        }
    }

    Context 'Expand-EmbeddedPythonInstallHints' {
        It 'Returns the original script when no placeholder token is present' {
            $scriptText = 'static python helper'
            Expand-EmbeddedPythonInstallHints -Script $scriptText -PackageNames @('requests') |
                Should -Be $scriptText
        }
    }
}
