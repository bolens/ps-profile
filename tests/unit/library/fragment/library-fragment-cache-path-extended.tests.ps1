<#
tests/unit/library-fragment-cache-path-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentCachePath directory resolution.
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
    Import-Module (Join-Path $libPath 'core/PlatformPaths.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $libPath 'fragment/FragmentCachePath.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'FragmentCachePathExtended'
    $script:OriginalCacheDir = $env:PS_PROFILE_CACHE_DIR
}

AfterAll {
    if ($null -eq $script:OriginalCacheDir) {
        Remove-Item Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_CACHE_DIR = $script:OriginalCacheDir
    }

    Remove-Module FragmentCachePath -ErrorAction SilentlyContinue -Force
    Remove-Module PlatformPaths -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentCachePath extended scenarios' {
    BeforeEach {
        if ($null -eq $script:OriginalCacheDir) {
            Remove-Item Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_CACHE_DIR = $script:OriginalCacheDir
        }
    }

    Context 'Get-FragmentCacheDbPath' {
        It 'Returns a path ending with fragment-cache.db' {
            $customCache = Join-Path $script:TempRoot 'db-path-cache'

            try {
                $env:PS_PROFILE_CACHE_DIR = $customCache
                Get-FragmentCacheDbPath | Should -Be (Join-Path $customCache 'fragment-cache.db')
            }
            finally {
                if ($null -eq $script:OriginalCacheDir) {
                    Remove-Item Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Creates the cache directory when EnsureExists is specified' {
            $customCache = Join-Path $script:TempRoot 'ensure-db-cache'

            try {
                $env:PS_PROFILE_CACHE_DIR = $customCache
                $dbPath = Get-FragmentCacheDbPath -EnsureExists

                $dbPath | Should -Be (Join-Path $customCache 'fragment-cache.db')
                Test-Path -LiteralPath $customCache | Should -Be $true
            }
            finally {
                if ($null -eq $script:OriginalCacheDir) {
                    Remove-Item Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'Get-FragmentCacheDirectory' {
        It 'Honors PS_PROFILE_CACHE_DIR overrides from PlatformPaths' {
            $customCache = Join-Path $script:TempRoot 'override-cache'

            try {
                $env:PS_PROFILE_CACHE_DIR = $customCache
                Get-FragmentCacheDirectory | Should -Be $customCache
            }
            finally {
                if ($null -eq $script:OriginalCacheDir) {
                    Remove-Item Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Resolves relative cache directories against the current location' {
            $relativeCache = Join-Path 'relative-cache-extended' ''
            $relativeCache = $relativeCache.TrimEnd('\', '/')

            try {
                $env:PS_PROFILE_CACHE_DIR = $relativeCache
                Get-FragmentCacheDirectory | Should -Be (Join-Path (Get-Location).Path $relativeCache)
            }
            finally {
                if ($null -eq $script:OriginalCacheDir) {
                    Remove-Item Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Creates missing cache directories when EnsureExists is enabled' {
            $customCache = Join-Path $script:TempRoot 'created-cache-dir'

            try {
                $env:PS_PROFILE_CACHE_DIR = $customCache
                Get-FragmentCacheDirectory -EnsureExists | Should -Be $customCache
                Test-Path -LiteralPath $customCache | Should -Be $true
            }
            finally {
                if ($null -eq $script:OriginalCacheDir) {
                    Remove-Item Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
