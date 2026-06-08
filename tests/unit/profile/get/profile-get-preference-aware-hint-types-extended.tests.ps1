<#
tests/unit/profile-get-preference-aware-hint-types-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-PreferenceAwareInstallHint tool type routing.
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

AfterAll {
    Remove-Item Env:\PS_RUST_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_GO_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_DOTNET_PACKAGE_MANAGER -ErrorAction SilentlyContinue
}

Describe 'Get-PreferenceAwareInstallHint tool types extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_RUST_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_GO_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_DOTNET_PACKAGE_MANAGER -ErrorAction SilentlyContinue
    }

    Context 'Language-specific tool types' {
        It 'Builds rust-package hints for cargo tooling' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'cargo-watch' -ToolType 'rust-package'
            $hint | Should -Match 'cargo-watch'
            $hint | Should -Match '^Install with:'
        }

        It 'Builds go-package hints for go tooling' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'golangci-lint' -ToolType 'go-package'
            $hint | Should -Match 'golangci-lint'
        }

        It 'Builds java-build-tool hints for gradle' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'gradle' -ToolType 'java-build-tool'
            $hint | Should -Match 'gradle'
        }

        It 'Builds dotnet-package hints for dotnet tooling' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'dotnet' -ToolType 'dotnet-package'
            $hint | Should -Match 'dotnet'
        }

        It 'Builds dart-package hints for dart tooling' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'dart' -ToolType 'dart-package'
            $hint | Should -Match 'dart'
        }
    }
}
