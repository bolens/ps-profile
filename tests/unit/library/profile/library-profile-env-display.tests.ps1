<#
tests/unit/library-profile-env-display.tests.ps1

.SYNOPSIS
    Unit tests for ProfileEnvDisplay module.
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
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfileEnvDisplay.psm1') -DisableNameChecking -Force -Global
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PROFILE_CUSTOM_TEST_FLAG -ErrorAction SilentlyContinue
}

Describe 'ProfileEnvDisplay Module' {
    Context 'Show-ProfileEnvVariables' {
        AfterEach {
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_CUSTOM_TEST_FLAG -ErrorAction SilentlyContinue
        }

        It 'Returns immediately when debug mode is disabled' {
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            { Show-ProfileEnvVariables } | Should -Not -Throw
        }

        It 'Runs summary output at debug level 1' {
            $env:PS_PROFILE_DEBUG = '1'
            $VerbosePreference = 'Continue'

            { Show-ProfileEnvVariables } | Should -Not -Throw
        }

        It 'Processes custom PS_PROFILE variables at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'
            $env:PS_PROFILE_CUSTOM_TEST_FLAG = '1'
            $VerbosePreference = 'Continue'

            { Show-ProfileEnvVariables } | Should -Not -Throw
            $env:PS_PROFILE_CUSTOM_TEST_FLAG | Should -Be '1'
        }
    }
}
