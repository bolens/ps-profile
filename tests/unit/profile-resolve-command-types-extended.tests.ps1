<#
tests/unit/profile-resolve-command-types-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Resolve-CommandInstallToolType classification.
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
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'Resolve-CommandInstallToolType extended scenarios' {
    Context 'Language runtime and package managers' {
        It 'Classifies rust tooling correctly' {
            Resolve-CommandInstallToolType -CommandName 'rustup' | Should -Be 'rust-package'
            Resolve-CommandInstallToolType -CommandName 'cargo' | Should -Be 'rust-package'
        }

        It 'Classifies go tooling correctly' {
            Resolve-CommandInstallToolType -CommandName 'go' | Should -Be 'go-package'
        }

        It 'Classifies ruby tooling correctly' {
            Resolve-CommandInstallToolType -CommandName 'gem' | Should -Be 'ruby-package'
            Resolve-CommandInstallToolType -CommandName 'bundle' | Should -Be 'ruby-package'
        }

        It 'Classifies dotnet tooling correctly' {
            Resolve-CommandInstallToolType -CommandName 'dotnet' | Should -Be 'dotnet-package'
            Resolve-CommandInstallToolType -CommandName 'nuget' | Should -Be 'dotnet-package'
        }

        It 'Classifies php tooling correctly' {
            Resolve-CommandInstallToolType -CommandName 'composer' | Should -Be 'php-package'
            Resolve-CommandInstallToolType -CommandName 'php' | Should -Be 'php-package'
        }

        It 'Classifies java build tooling correctly' {
            Resolve-CommandInstallToolType -CommandName 'mvn' | Should -Be 'java-build-tool'
            Resolve-CommandInstallToolType -CommandName 'gradle' | Should -Be 'java-build-tool'
            Resolve-CommandInstallToolType -CommandName 'ant' | Should -Be 'java-build-tool'
        }

        It 'Classifies python runtime commands correctly' {
            Resolve-CommandInstallToolType -CommandName 'python' | Should -Be 'python-runtime'
            Resolve-CommandInstallToolType -CommandName 'python3' | Should -Be 'python-runtime'
        }
    }

    Context 'Normalization' {
        It 'Trims and lowercases command names before matching' {
            Resolve-CommandInstallToolType -CommandName '  GRADLE  ' | Should -Be 'java-build-tool'
            Resolve-CommandInstallToolType -CommandName 'NPM' | Should -Be 'node-package'
        }
    }
}
