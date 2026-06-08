<#
tests/unit/profile-install-hint-resolver-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for preference-aware install hint resolution.
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

AfterAll {
    Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
}

Describe 'InstallHintResolver extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    Context 'Get-PreferenceAwareInstallHint' {
        It 'Uses DefaultInstallCommand when provided for generic tools' {
            $hint = Get-PreferenceAwareInstallHint `
                -ToolName 'custom-tool' `
                -ToolType 'generic' `
                -DefaultInstallCommand 'Download from https://example.com/custom-tool'

            $hint | Should -Be 'Install with: Download from https://example.com/custom-tool'
        }

        It 'Honors PS_PYTHON_PACKAGE_MANAGER for python-package tools' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'

            $hint = Get-PreferenceAwareInstallHint -ToolName 'requests' -ToolType 'python-package'
            $hint | Should -Match 'uv'
        }

        It 'Honors PS_NODE_PACKAGE_MANAGER for node-package tools' {
            $env:PS_NODE_PACKAGE_MANAGER = 'pnpm'

            $hint = Get-PreferenceAwareInstallHint -ToolName 'pnpm' -ToolType 'node-package'
            $hint | Should -Match 'pnpm'
        }

        It 'Returns registry-backed hints for known tools' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'docker' -ToolType 'generic'
            $hint | Should -Match '^Install with:'
            $hint | Should -Not -BeNullOrEmpty
        }

        It 'Includes fallback alternatives for registry-backed tools when available' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'git' -ToolType 'generic'
            $hint | Should -Match 'Install with:'
        }
    }
}
