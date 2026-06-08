<#
tests/unit/profile-language-base-version-manager-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Register-LanguageModule version manager and build helpers.
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
            'FunctionRegistration.ps1'
            'LanguageBase.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'LanguageBase version manager extended scenarios' {
    BeforeEach {
        $script:Suffix = Get-Random
        $script:LanguageName = "VersionLang$script:Suffix"
        $script:CommandName = "versionlangcmd$script:Suffix"
        $script:VersionManager = "versionmgr$script:Suffix"
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    AfterEach {
        foreach ($name in @(
                "Invoke-$($script:LanguageName)"
                "Invoke-$($script:VersionManager)"
                "Build-$($script:LanguageName)Project"
                "Test-$($script:LanguageName)Project"
                "Run-$($script:LanguageName)Project"
            )) {
            Remove-Item -Path "Function:\$name" -Force -ErrorAction SilentlyContinue
        }
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    Context 'Register-LanguageModule' {
        It 'Registers a version manager wrapper when VersionManager is provided' {
            $null = Register-LanguageModule `
                -LanguageName $script:LanguageName `
                -CommandName $script:CommandName `
                -VersionManager $script:VersionManager

            Get-Command "Invoke-$($script:VersionManager)" -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'Collects warnings when invoke is called without the runtime command' {
            $null = Register-LanguageModule `
                -LanguageName $script:LanguageName `
                -CommandName $script:CommandName

            Set-TestCommandAvailabilityState -CommandName $script:CommandName -Available $false
            & "Invoke-$($script:LanguageName)"

            $global:CollectedMissingToolWarnings.Count | Should -BeGreaterThan (0)
            $global:CollectedMissingToolWarnings[0].Tool | Should -Be $script:CommandName
        }

        It 'Accepts custom build command tokens during registration' {
            $null = Register-LanguageModule `
                -LanguageName $script:LanguageName `
                -CommandName $script:CommandName `
                -BuildCommand 'compile step'

            Get-Command "Build-$($script:LanguageName)Project" -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'Returns false when the command name is blank' {
            Register-LanguageModule -LanguageName $script:LanguageName -CommandName '   ' |
                Should -Be $false
        }
    }
}
