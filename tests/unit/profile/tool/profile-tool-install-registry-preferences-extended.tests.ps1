<#
tests/unit/profile-tool-install-registry-preferences-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for preference-aware package manager fallback chains.
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
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

AfterAll {
    Remove-Item Env:\PS_RUST_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PYTHON_RUNTIME -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
}

Describe 'ToolInstallRegistry preferences extended scenarios' {
    Context 'Get-SystemPackageManagerFallbackChain' {
        It 'Returns Windows package manager metadata for explicit platform' {
            $result = Get-SystemPackageManagerFallbackChain -ToolName 'jq' -Platform 'Windows'

            $result.Platform | Should -Be 'Windows'
            $result.Available | Should -Not -BeNullOrEmpty
            ($result.Available -join ' ') | Should -Match 'jq'
        }

        It 'Returns Linux package manager metadata for explicit platform' {
            $result = Get-SystemPackageManagerFallbackChain -ToolName 'jq' -Platform 'Linux'

            $result.Platform | Should -Be 'Linux'
            ($result.Available -join ' ') | Should -Match 'jq'
        }

        It 'Returns macOS package manager metadata for explicit platform' {
            $result = Get-SystemPackageManagerFallbackChain -ToolName 'jq' -Platform 'macOS'

            $result.Platform | Should -Be 'macOS'
            ($result.Available -join ' ') | Should -Match 'jq'
        }

        It 'Builds a fallback chain string when methods are available' {
            $result = Get-SystemPackageManagerFallbackChain -ToolName 'git' -Platform 'Windows'
            $result.FallbackChain | Should -Not -BeNullOrEmpty
        }

        It 'Accepts a preferred manager without failing for unknown values' {
            $result = Get-SystemPackageManagerFallbackChain `
                -ToolName 'git' `
                -Platform 'Windows' `
                -PreferredManager 'nonexistent-pm'

            $result | Should -Not -BeNullOrEmpty
            $result.Platform | Should -Be 'Windows'
        }
    }

    Context 'Test-PreferenceAwareInstallPreferences' {
        AfterEach {
            Remove-Item Env:\PS_RUST_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PYTHON_RUNTIME -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        }

        It 'Validates rust package manager preferences' {
            $env:PS_RUST_PACKAGE_MANAGER = 'cargo'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'rust-package'

            $result.Valid | Should -Be $true
            $result.Preferences['PS_RUST_PACKAGE_MANAGER'] | Should -Be 'cargo'
        }

        It 'Detects invalid rust package manager preferences' {
            $env:PS_RUST_PACKAGE_MANAGER = 'invalid-rust-pm'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'rust-package'

            $result.Valid | Should -Be $false
            $result.Errors | Should -Match 'PS_RUST_PACKAGE_MANAGER'
        }

        It 'Validates python runtime preferences independently' {
            $env:PS_PYTHON_RUNTIME = 'python3'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'python-runtime'

            $result.Valid | Should -Be $true
            $result.Preferences['PS_PYTHON_RUNTIME'] | Should -Be 'python3'
        }

        It 'Includes system package manager preference in all-mode validation' {
            $env:PS_SYSTEM_PACKAGE_MANAGER = 'auto'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'all'

            $result.Preferences.ContainsKey('PS_SYSTEM_PACKAGE_MANAGER') | Should -Be $true
            $result.Preferences['PS_SYSTEM_PACKAGE_MANAGER'] | Should -Be 'auto'
        }
    }
}
