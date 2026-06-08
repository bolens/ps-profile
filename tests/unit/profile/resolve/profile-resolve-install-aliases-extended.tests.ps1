<#
tests/unit/profile-resolve-install-aliases-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Resolve-InstallPackageName alias mappings.
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

Describe 'Resolve-InstallPackageName alias extended scenarios' {
    Context 'Cloud and infrastructure aliases' {
        It 'Maps azure CLI shorthand to azure-cli' {
            Resolve-InstallPackageName -ToolName 'az' | Should -Be 'azure-cli'
        }

        It 'Maps tofu shorthand to opentofu' {
            Resolve-InstallPackageName -ToolName 'tofu' | Should -Be 'opentofu'
        }

        It 'Maps fly shorthand to flyctl' {
            Resolve-InstallPackageName -ToolName 'fly' | Should -Be 'flyctl'
        }
    }

    Context 'Media and document aliases' {
        It 'Maps imagemagick command aliases' {
            Resolve-InstallPackageName -ToolName 'magick' | Should -Be 'imagemagick'
            Resolve-InstallPackageName -ToolName 'convert' | Should -Be 'imagemagick'
        }

        It 'Maps graphicsmagick gm shorthand' {
            Resolve-InstallPackageName -ToolName 'gm' | Should -Be 'graphicsmagick'
        }

        It 'Maps handbrake-cli to handbrake' {
            Resolve-InstallPackageName -ToolName 'handbrake-cli' | Should -Be 'handbrake'
        }
    }

    Context 'Database and language aliases' {
        It 'Maps database client shorthands' {
            Resolve-InstallPackageName -ToolName 'psql' | Should -Be 'postgresql'
            Resolve-InstallPackageName -ToolName 'sqlite' | Should -Be 'sqlite3'
        }

        It 'Maps node and dotnet shorthands' {
            Resolve-InstallPackageName -ToolName 'node' | Should -Be 'nodejs'
            Resolve-InstallPackageName -ToolName 'dotnet' | Should -Be 'dotnet-sdk'
        }

        It 'Maps package manager shorthands' {
            Resolve-InstallPackageName -ToolName 'choco' | Should -Be 'chocolatey'
            Resolve-InstallPackageName -ToolName 'brew' | Should -Be 'homebrew'
        }
    }
}
