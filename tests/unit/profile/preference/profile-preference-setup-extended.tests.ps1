<#
tests/unit/profile-preference-setup-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Set-PreferenceAwareInstallPreferences non-interactive setup.
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
    Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
}

Describe 'Set-PreferenceAwareInstallPreferences extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    Context 'NonInteractive mode' {
        It 'Preserves existing python package manager preference without prompting' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'

            $result = Set-PreferenceAwareInstallPreferences -PreferenceType 'python-package' -NonInteractive

            $result.Updated.Count | Should -Be 0
            $env:PS_PYTHON_PACKAGE_MANAGER | Should -Be 'uv'
        }

        It 'Preserves existing node package manager preference without prompting' {
            $env:PS_NODE_PACKAGE_MANAGER = 'pnpm'

            $result = Set-PreferenceAwareInstallPreferences -PreferenceType 'node-package' -NonInteractive

            $result.Updated.Count | Should -Be 0
            $env:PS_NODE_PACKAGE_MANAGER | Should -Be 'pnpm'
        }

        It 'Leaves unset preferences unchanged in non-interactive mode' {
            $result = Set-PreferenceAwareInstallPreferences -PreferenceType 'python-package' -NonInteractive

            $result.Updated.Count | Should -Be 0
            $env:PS_PYTHON_PACKAGE_MANAGER | Should -BeNullOrEmpty
        }

        It 'Returns a result hashtable for system-package setup' {
            $result = Set-PreferenceAwareInstallPreferences -PreferenceType 'system-package' -NonInteractive

            $result | Should -Not -BeNullOrEmpty
            $result.Keys | Should -Contain 'Preferences'
            $result.Keys | Should -Contain 'Updated'
        }

        It 'Runs without Read-Host in non-interactive mode for all preferences' {
            { Set-PreferenceAwareInstallPreferences -PreferenceType 'all' -NonInteractive } | Should -Not -Throw
        }
    }
}
