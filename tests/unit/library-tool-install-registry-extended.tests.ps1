<#
tests/unit/library-tool-install-registry-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for tool install registry and fallback chains.
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
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'ToolInstallRegistry extended scenarios' {
    Context 'Get-ToolInstallMethodRegistry' {
        It 'Includes registry entries for common developer tools' {
            $registry = Get-ToolInstallMethodRegistry

            $registry.ContainsKey('pnpm') | Should -Be $true
            $registry.ContainsKey('uv') | Should -Be $true
            $registry['pnpm'].ContainsKey('Linux') | Should -Be $true
        }

        It 'Returns independent registry copies on each call' {
            $first = Get-ToolInstallMethodRegistry
            $second = Get-ToolInstallMethodRegistry

            $first.GetHashCode() | Should -Not -Be $second.GetHashCode()
        }
    }

    Context 'Get-ToolSpecificInstallMethod' {
        It 'Resolves install commands for known tools on Linux' {
            $command = Get-ToolSpecificInstallMethod -ToolName 'pnpm' -Platform 'Linux' -PreferredMethod 'npm'
            $command | Should -Match 'pnpm'
        }

        It 'Returns null for unknown tools' {
            Get-ToolSpecificInstallMethod -ToolName 'totally-unknown-tool-xyz' -Platform 'Linux' | Should -BeNullOrEmpty
        }
    }

    Context 'Get-InstallMethodFallbackChain' {
        It 'Formats primary and fallback methods into a readable chain' {
            $chain = Get-InstallMethodFallbackChain `
                -PreferredMethod 'scoop install git' `
                -FallbackMethods @('winget install git', 'choco install git')

            $chain | Should -Match 'scoop install git'
            $chain | Should -Match 'or: winget install git'
        }

        It 'Respects MaxFallbacks when building the chain' {
            $chain = Get-InstallMethodFallbackChain `
                -PreferredMethod 'primary' `
                -FallbackMethods @('fallback1', 'fallback2', 'fallback3', 'fallback4') `
                -MaxFallbacks 1

            $chain | Should -Match 'primary'
            $chain | Should -Match 'fallback1'
            $chain | Should -Not -Match 'fallback2'
        }
    }

    Context 'Test-CommandAvailable' {
        It 'Returns true for commands that exist in the current session' {
            Test-CommandAvailable -CommandName 'pwsh' | Should -Be $true
        }

        It 'Returns false for nonexistent commands' {
            Test-CommandAvailable -CommandName 'definitely-missing-command-xyz-12345' | Should -Be $false
        }
    }
}
