<#
tests/unit/profile-embedded-node-resolve-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Node embedded install hint resolution helpers.
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
}

Describe 'Embedded Node install hint resolve extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    AfterEach {
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    Context 'Resolve-NodeInstallHintMessage' {
        It 'Replaces __NODE_INSTALL_CMD__ placeholders in messages' {
            $resolved = Resolve-NodeInstallHintMessage `
                -Message 'Run __NODE_INSTALL_CMD__ before continuing' `
                -PackageNames @('typescript')

            $resolved | Should -Not -Match '__NODE_INSTALL_CMD__'
            $resolved | Should -Match 'typescript'
        }

        It 'Returns the original message when no placeholder is present' {
            $message = 'No install step required'
            Resolve-NodeInstallHintMessage -Message $message -PackageNames @('json5') | Should -Be $message
        }
    }

    Context 'global:Get-NodePackageInstallRecommendation' {
        It 'Builds recommendations from the PackageName parameter' {
            $command = global:Get-NodePackageInstallRecommendation -PackageName 'json5'
            $command | Should -Match 'json5'
        }

        It 'Uses global install syntax when Global is specified' {
            $command = Get-NodePackageInstallCommandCore -PackageNames @('json5') -Global
            $command | Should -Match 'json5'
            $command | Should -Match '-g|global add'
        }
    }

    Context 'Expand-EmbeddedNodeInstallHints' {
        It 'Returns the original script when no placeholder token is present' {
            $scriptText = 'No placeholder here'
            Expand-EmbeddedNodeInstallHints -Script $scriptText -PackageNames @('json5') |
                Should -Be $scriptText
        }
    }
}
