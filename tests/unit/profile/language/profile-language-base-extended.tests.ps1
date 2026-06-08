<#
tests/unit/profile-language-base-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for LanguageBase module registration helpers.
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
            'MissingToolWarnings.ps1'
            'FunctionRegistration.ps1'
            'LanguageBase.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'LanguageBase extended scenarios' {
    BeforeAll {
        $script:PackageManager = $null
        $script:CustomCommandName = $null
    }

    BeforeEach {
        $script:LanguageName = "ExtendedLang$(Get-Random)"
        $script:CommandName = "extendedlangcmd$(Get-Random)"
        $script:PackageManager = $null
        $script:CustomCommandName = $null
    }

    AfterEach {
        foreach ($name in @(
                "Invoke-$($script:LanguageName)"
                "Build-$($script:LanguageName)Project"
                "Test-$($script:LanguageName)Project"
                "Run-$($script:LanguageName)Project"
                $(if ($script:PackageManager) { "Invoke-$($script:PackageManager)" })
                $script:CustomCommandName
            )) {
            if ($name) {
                Remove-Item -Path "Function:\global:$name" -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Register-LanguageModule' {
        It 'Registers invoke, build, test, and run helpers for a language' {
            $null = Register-LanguageModule -LanguageName $script:LanguageName -CommandName $script:CommandName

            Get-Command "Invoke-$($script:LanguageName)" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command "Build-$($script:LanguageName)Project" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command "Test-$($script:LanguageName)Project" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command "Run-$($script:LanguageName)Project" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers a package manager wrapper when PackageManager is provided' {
            $script:PackageManager = "extpkg$(Get-Random)"
            $null = Register-LanguageModule `
                -LanguageName $script:LanguageName `
                -CommandName $script:CommandName `
                -PackageManager $script:PackageManager

            Get-Command "Invoke-$($script:PackageManager)" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers custom commands from the CustomCommands hashtable' {
            $script:CustomCommandName = "Invoke-ExtendedCustom$(Get-Random)"
            $customBody = { return 'custom-language-command' }

            $null = Register-LanguageModule `
                -LanguageName $script:LanguageName `
                -CommandName $script:CommandName `
                -CustomCommands @{ $script:CustomCommandName = $customBody }

            Get-Command $script:CustomCommandName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Returns false when required language metadata is blank' {
            Register-LanguageModule -LanguageName '   ' -CommandName $script:CommandName | Should -Be $false
        }
    }
}
