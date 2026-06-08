<#
tests/unit/library-profile-version-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Initialize-ProfileVersion lazy git commit behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/profile/ProfileVersion.psm1') -DisableNameChecking -Force -Global
    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileVersionExtended'
}

AfterAll {
    Remove-Module ProfileVersion -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileVersion extended scenarios' {
    AfterEach {
        Remove-Variable -Name PSProfileVersion, PSProfileGitCommit, PSProfileGitCommitCalculated, PSProfileGitCommitGetter -Scope Global -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    }

    Context 'Initialize-ProfileVersion' {
        It 'Returns the same commit hash on repeated getter invocations' {
            Initialize-ProfileVersion -ProfileDir $script:TempDir -ProfileVersion '1.2.3'

            $first = & $global:PSProfileGitCommitGetter
            $second = & $global:PSProfileGitCommitGetter

            $first | Should -Be $second
            $global:PSProfileGitCommitCalculated | Should -Be $true
        }

        It 'Does not recreate the git commit getter on subsequent initialization' {
            Initialize-ProfileVersion -ProfileDir $script:TempDir -ProfileVersion '1.0.0'
            $originalGetter = $global:PSProfileGitCommitGetter

            Initialize-ProfileVersion -ProfileDir $script:TempDir -ProfileVersion '9.9.9'

            $global:PSProfileGitCommitGetter | Should -Be $originalGetter
        }

        It 'Runs without error when debug output is enabled' {
            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            { Initialize-ProfileVersion -ProfileDir $script:TempDir -ProfileVersion 'debug-test' } | Should -Not -Throw
        }

        It 'Defaults to version 1.0.0 when ProfileVersion is omitted' {
            Initialize-ProfileVersion -ProfileDir $script:TempDir

            $global:PSProfileVersion | Should -Be '1.0.0'
        }
    }
}
