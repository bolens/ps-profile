<#
tests/unit/library-profile-version-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Initialize-ProfileVersion lazy git commit behavior.
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
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/profile/ProfileVersion.psm1') -DisableNameChecking -Force -Global
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
        Remove-Item Env:\PS_PROFILE_VERSION_FORCE_COMMIT -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_VERSION_FORCE_GIT_FAILURE -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_VERSION_FORCE_PUSH_FAILURE -ErrorAction SilentlyContinue
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

        It 'Returns unknown when git rev-parse fails in an isolated repository directory' {
            $gitRepoDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ProfileVersionInvalidGit-{0}" -f ([guid]::NewGuid().ToString()))
            New-Item -ItemType Directory -Path $gitRepoDir -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $gitRepoDir '.git') -Force | Out-Null

            try {
                $env:PS_PROFILE_DEBUG = '2'
                $VerbosePreference = 'Continue'

                Initialize-ProfileVersion -ProfileDir $gitRepoDir -ProfileVersion '3.1.0'
                & $global:PSProfileGitCommitGetter | Should -Be 'unknown'
            }
            finally {
                Remove-Item -LiteralPath $gitRepoDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns unknown when git throws inside the repository directory' {
            $gitRepoDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ProfileVersionGitThrow-{0}" -f ([guid]::NewGuid().ToString()))
            New-Item -ItemType Directory -Path $gitRepoDir -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $gitRepoDir '.git') -Force | Out-Null

            try {
                Mock git {
                    throw [System.InvalidOperationException]::new('git exception probe')
                }

                Initialize-ProfileVersion -ProfileDir $gitRepoDir -ProfileVersion '3.2.0'
                & $global:PSProfileGitCommitGetter | Should -Be 'unknown'
            }
            finally {
                Remove-Item -LiteralPath $gitRepoDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns unknown when the profile directory disappears before commit lookup' {
            $gitRepoDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ProfileVersionMissingDir-{0}" -f ([guid]::NewGuid().ToString()))
            New-Item -ItemType Directory -Path $gitRepoDir -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $gitRepoDir '.git') -Force | Out-Null

            try {
                $env:PS_PROFILE_DEBUG = '2'
                $VerbosePreference = 'Continue'

                Initialize-ProfileVersion -ProfileDir $gitRepoDir -ProfileVersion '3.3.0'
                Remove-Item -LiteralPath $gitRepoDir -Recurse -Force
                & $global:PSProfileGitCommitGetter | Should -Be 'unknown'
            }
            finally {
                if (Test-Path -LiteralPath $gitRepoDir) {
                    Remove-Item -LiteralPath $gitRepoDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Emits level 1 initialization diagnostics when debug output is enabled' {
            $env:PS_PROFILE_DEBUG = '1'
            $VerbosePreference = 'Continue'

            Initialize-ProfileVersion -ProfileDir $script:TempDir -ProfileVersion '8.0.0'

            $global:PSProfileVersion | Should -Be '8.0.0'
        }

        It 'Returns git commit hash when .git exists and git succeeds' {
            $gitRepoDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ProfileVersionGitRepo-{0}" -f ([guid]::NewGuid().ToString()))
            New-Item -ItemType Directory -Path $gitRepoDir -Force | Out-Null

            try {
                git -C $gitRepoDir init -q | Out-Null
                git -C $gitRepoDir config user.email 'probe@example.com' | Out-Null
                git -C $gitRepoDir config user.name 'Probe User' | Out-Null
                git -C $gitRepoDir commit --allow-empty -m 'probe' -q | Out-Null

                Initialize-ProfileVersion -ProfileDir $gitRepoDir -ProfileVersion '2.3.4'
                $commit = & $global:PSProfileGitCommitGetter
                $commit | Should -Match '^[0-9a-f]+$'
                $commit.Length | Should -BeLessOrEqual 8
            }
            finally {
                Remove-Item -LiteralPath $gitRepoDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns unknown when git command fails inside a git repository' {
            $gitRepoDir = New-TestTempDirectory -Prefix 'ProfileVersionGitFail'
            New-Item -ItemType Directory -Path (Join-Path $gitRepoDir '.git') -Force | Out-Null

            try {
                $env:PS_PROFILE_VERSION_FORCE_GIT_FAILURE = '1'
                $env:PS_PROFILE_DEBUG = '2'
                $VerbosePreference = 'Continue'

                Initialize-ProfileVersion -ProfileDir $gitRepoDir -ProfileVersion '3.0.0'
                & $global:PSProfileGitCommitGetter | Should -Be 'unknown'
            }
            finally {
                Remove-Item Env:\PS_PROFILE_VERSION_FORCE_GIT_FAILURE -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $gitRepoDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns unknown when changing into the profile directory fails' {
            $gitRepoDir = New-TestTempDirectory -Prefix 'ProfileVersionPushFail'
            New-Item -ItemType Directory -Path (Join-Path $gitRepoDir '.git') -Force | Out-Null

            try {
                $env:PS_PROFILE_VERSION_FORCE_PUSH_FAILURE = '1'
                $env:PS_PROFILE_DEBUG = '2'
                $VerbosePreference = 'Continue'

                Initialize-ProfileVersion -ProfileDir $gitRepoDir -ProfileVersion '4.0.0'
                & $global:PSProfileGitCommitGetter | Should -Be 'unknown'
            }
            finally {
                Remove-Item Env:\PS_PROFILE_VERSION_FORCE_PUSH_FAILURE -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $gitRepoDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Emits level 3 git diagnostics when debug output is enabled' {
            $gitRepoDir = New-TestTempDirectory -Prefix 'ProfileVersionGitDebug'
            New-Item -ItemType Directory -Path (Join-Path $gitRepoDir '.git') -Force | Out-Null

            try {
                $env:PS_PROFILE_VERSION_FORCE_COMMIT = 'cafebabe'
                $env:PS_PROFILE_DEBUG = '3'
                $VerbosePreference = 'Continue'

                Initialize-ProfileVersion -ProfileDir $gitRepoDir -ProfileVersion '5.0.0'
                & $global:PSProfileGitCommitGetter | Should -Be 'cafebabe'
            }
            finally {
                Remove-Item Env:\PS_PROFILE_VERSION_FORCE_COMMIT -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $gitRepoDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Emits level 3 diagnostics when git directory is missing' {
            $noGitDir = New-TestTempDirectory -Prefix 'ProfileVersionNoGitDebug'

            try {
                $env:PS_PROFILE_DEBUG = '3'
                $VerbosePreference = 'Continue'

                Initialize-ProfileVersion -ProfileDir $noGitDir -ProfileVersion '6.0.0'
                & $global:PSProfileGitCommitGetter | Should -Be 'unknown'
            }
            finally {
                Remove-Item -LiteralPath $noGitDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Skips getter recreation when PSProfileGitCommitGetter already exists globally' {
            $global:PSProfileGitCommitGetter = { 'preset-hash' }.GetNewClosure()

            Initialize-ProfileVersion -ProfileDir $script:TempDir -ProfileVersion '7.0.0'

            & $global:PSProfileGitCommitGetter | Should -Be 'preset-hash'
            $global:PSProfileVersion | Should -Be '7.0.0'
        }
    }
}
