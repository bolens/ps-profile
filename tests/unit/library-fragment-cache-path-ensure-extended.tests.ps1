<#
tests/unit/library-fragment-cache-path-ensure-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentCachePath helpers.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:FragmentCachePathModule = Join-Path $PSScriptRoot '../../scripts/lib/fragment/FragmentCachePath.psm1'
    Import-Module $script:FragmentCachePathModule -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'FragmentCachePathExtended'
}

AfterAll {
    if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
        Restore-AllMocks
    }

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Fragment cache path extended scenarios' {
    AfterEach {
        if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
            Restore-AllMocks
        }
    }

    Context 'Get-FragmentCacheDirectory' {
        It 'Creates cache directory when EnsureExists is specified' {
            $customCache = Join-Path $script:TempDir 'custom-cache'
            Mock-EnvironmentVariable -Name 'PS_PROFILE_CACHE_DIR' -Value $customCache

            $cacheDir = Get-FragmentCacheDirectory -EnsureExists

            $cacheDir | Should -Be $customCache
            Test-Path -LiteralPath $customCache -PathType Container | Should -Be $true
        }
    }

    Context 'Get-FragmentCacheDbPath' {
        It 'Places database file inside the ensured cache directory' {
            $customCache = Join-Path $script:TempDir 'db-cache'
            Mock-EnvironmentVariable -Name 'PS_PROFILE_CACHE_DIR' -Value $customCache

            $dbPath = Get-FragmentCacheDbPath -EnsureExists

            Split-Path -Parent $dbPath | Should -Be $customCache
            Test-Path -LiteralPath $customCache -PathType Container | Should -Be $true
            $dbPath | Should -Match 'fragment-cache\.db$'
        }
    }
}
