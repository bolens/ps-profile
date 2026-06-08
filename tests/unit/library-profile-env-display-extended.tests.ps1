<#
tests/unit/library-profile-env-display-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Show-ProfileEnvVariables debug level handling.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/profile/ProfileEnvDisplay.psm1') -DisableNameChecking -Force -Global
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PROFILE_EXTENDED_FLAG -ErrorAction SilentlyContinue
}

Describe 'ProfileEnvDisplay extended scenarios' {
    AfterEach {
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_EXTENDED_FLAG -ErrorAction SilentlyContinue
    }

    Context 'Show-ProfileEnvVariables' {
        It 'Treats non-numeric debug values as disabled' {
            $env:PS_PROFILE_DEBUG = 'not-a-number'

            { Show-ProfileEnvVariables } | Should -Not -Throw
        }

        It 'Preserves custom PS_PROFILE variables at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'
            $env:PS_PROFILE_EXTENDED_FLAG = 'keep-me'
            $VerbosePreference = 'Continue'

            Show-ProfileEnvVariables

            $env:PS_PROFILE_EXTENDED_FLAG | Should -Be 'keep-me'
        }

        It 'Runs summary output at debug level 2 without throwing' {
            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            { Show-ProfileEnvVariables } | Should -Not -Throw
        }

        It 'Returns immediately when PS_PROFILE_DEBUG is unset' {
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            { Show-ProfileEnvVariables } | Should -Not -Throw
        }
    }
}
