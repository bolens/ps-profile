<#
tests/unit/library-profile-version.tests.ps1

.SYNOPSIS
    Unit tests for ProfileVersion module.
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
    Import-Module (Join-Path $libPath 'profile/ProfileVersion.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileVersionTests'
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileVersion Module' {
    Context 'Initialize-ProfileVersion' {
        AfterEach {
            Remove-Variable -Name PSProfileVersion -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name PSProfileGitCommit -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name PSProfileGitCommitCalculated -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name PSProfileGitCommitGetter -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Initializes version metadata once' {
            Initialize-ProfileVersion -ProfileDir $script:TempDir -ProfileVersion '9.8.7'

            $global:PSProfileVersion | Should -Be '9.8.7'
            $global:PSProfileGitCommitCalculated | Should -Be $false
            Get-Variable -Name PSProfileGitCommitGetter -Scope Global | Should -Not -BeNullOrEmpty
        }

        It 'Does not overwrite an existing profile version' {
            $global:PSProfileVersion = 'existing-version'
            Initialize-ProfileVersion -ProfileDir $script:TempDir -ProfileVersion '2.0.0'

            $global:PSProfileVersion | Should -Be 'existing-version'
        }

        It 'Returns unknown commit hash when profile directory is not a git repo' {
            Remove-Variable -Name PSProfileVersion, PSProfileGitCommit, PSProfileGitCommitCalculated, PSProfileGitCommitGetter -Scope Global -ErrorAction SilentlyContinue

            $profileDir = (Resolve-Path -LiteralPath $script:TempDir).Path
            Initialize-ProfileVersion -ProfileDir $profileDir

            & $global:PSProfileGitCommitGetter | Should -Be 'unknown'
            $global:PSProfileGitCommitCalculated | Should -Be $true
        }
    }
}
