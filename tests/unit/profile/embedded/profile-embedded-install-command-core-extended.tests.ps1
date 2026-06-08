<#
tests/unit/profile-embedded-install-command-core-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for embedded node/python install command core helpers.
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

Describe 'Embedded install command core extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    Context 'Get-NodePackageInstallCommandCore' {
        It 'Returns null when all package names are blank' {
            Get-NodePackageInstallCommandCore -PackageNames @('   ') | Should -BeNullOrEmpty
        }

        It 'Builds install commands for a single package name' {
            $command = Get-NodePackageInstallCommandCore -PackageNames @('typescript')
            $command | Should -Match 'typescript'
        }

        It 'Combines multiple package names into one install command' {
            $command = Get-NodePackageInstallCommandCore -PackageNames @('eslint', 'prettier')
            $command | Should -Match 'eslint'
            $command | Should -Match 'prettier'
        }
    }

    Context 'Get-PythonPackageInstallCommandCore' {
        It 'Returns null when all package names are blank' {
            Get-PythonPackageInstallCommandCore -PackageNames @('   ') | Should -BeNullOrEmpty
        }

        It 'Uses the PythonCmd override in the fallback install command' {
            $originalHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue

            try {
                $command = Get-PythonPackageInstallCommandCore `
                    -PackageNames @('requests') `
                    -PythonCmd 'python3.12'
                $command | Should -Match 'python3.12'
                $command | Should -Match 'requests'
            }
            finally {
                if ($null -ne $originalHint) {
                    Set-Item -Path Function:\global:Get-PreferenceAwareInstallHint -Value $originalHint.ScriptBlock -Force
                }
            }
        }

        It 'Combines multiple python package names into one command' {
            $command = Get-PythonPackageInstallCommandCore -PackageNames @('numpy', 'pandas')
            $command | Should -Match 'numpy'
            $command | Should -Match 'pandas'
        }
    }
}
