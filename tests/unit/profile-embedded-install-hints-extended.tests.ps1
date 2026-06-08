<#
tests/unit/profile-embedded-install-hints-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for embedded install hint helpers.
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
    Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
}

Describe 'EmbeddedInstallHints extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    Context 'Get-EmbeddedInstallCommandFromHint' {
        It 'Extracts commands from Install with prefixes' {
            $command = Get-EmbeddedInstallCommandFromHint -Hint 'Install with: scoop install jq'
            $command | Should -Be 'scoop install jq'
        }

        It 'Returns null for blank hints' {
            Get-EmbeddedInstallCommandFromHint -Hint '' | Should -BeNullOrEmpty
            Get-EmbeddedInstallCommandFromHint -Hint '   ' | Should -BeNullOrEmpty
        }

        It 'Returns trimmed hints that are already bare commands' {
            Get-EmbeddedInstallCommandFromHint -Hint '  npm install -g typescript  ' |
                Should -Be 'npm install -g typescript'
        }
    }

    Context 'Get-NodePackageInstallCommandCore' {
        It 'Falls back to npm when no preference is configured' {
            $command = Get-NodePackageInstallCommandCore -PackageNames 'json5'
            $command | Should -Match 'json5'
            $command | Should -Match 'npm install'
        }

        It 'Combines multiple package names into one install command' {
            $command = Get-NodePackageInstallCommandCore -PackageNames @('bson', 'cbor') -Global
            $command | Should -Match 'bson'
            $command | Should -Match 'cbor'
        }
    }

    Context 'Expand-EmbeddedNodeInstallHints' {
        It 'Replaces placeholder tokens in embedded scripts' {
            $expanded = Expand-EmbeddedNodeInstallHints `
                -Script "console.error('Install with: __NODE_INSTALL_CMD__');" `
                -PackageNames 'json5' `
                -Global

            $expanded | Should -Not -Match '__NODE_INSTALL_CMD__'
            $expanded | Should -Match 'json5'
        }
    }
}
