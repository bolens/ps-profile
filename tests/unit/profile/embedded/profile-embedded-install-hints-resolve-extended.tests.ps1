<#
tests/unit/profile-embedded-install-hints-resolve-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for embedded install hint resolution helpers.
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
            'EmbeddedInstallHints.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

AfterAll {
    Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
}

Describe 'EmbeddedInstallHints resolve extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    Context 'Resolve-NodeInstallHintMessage' {
        It 'Replaces __NODE_INSTALL_CMD__ placeholders in user-facing messages' {
            $resolved = Resolve-NodeInstallHintMessage `
                -Message 'Install with: __NODE_INSTALL_CMD__' `
                -PackageNames @('json5')

            $resolved | Should -Not -Match '__NODE_INSTALL_CMD__'
            $resolved | Should -Match 'json5'
        }

        It 'Returns the original message when no placeholder token is present' {
            $message = 'No install hint required'
            Resolve-NodeInstallHintMessage -Message $message -PackageNames @('json5') | Should -Be $message
        }
    }

    Context 'Get-NodePackageInstallRecommendation' {
        It 'Accepts PackageName as a singular alias for PackageNames' {
            $command = global:Get-NodePackageInstallRecommendation -PackageName 'typescript' -Global
            $command | Should -Match 'typescript'
        }

        It 'Combines multiple package names into one recommendation' {
            $command = global:Get-NodePackageInstallRecommendation -PackageNames @('bson', 'cbor')
            $command | Should -Match 'bson'
            $command | Should -Match 'cbor'
        }
    }

    Context 'Get-PythonPackageInstallRecommendation' {
        It 'Passes the Global switch through to install command generation' {
            $command = global:Get-PythonPackageInstallRecommendation -PackageName 'numpy' -Global
            $command | Should -Match 'numpy'
        }

        It 'Expands embedded scripts with multiple Python package placeholders' {
            $expanded = Expand-EmbeddedPythonInstallHints `
                -Script 'deps: __PYTHON_INSTALL_CMD__' `
                -PackageNames @('numpy', 'pandas')

            $expanded | Should -Not -Match '__PYTHON_INSTALL_CMD__'
            $expanded | Should -Match 'numpy'
            $expanded | Should -Match 'pandas'
        }
    }
}
