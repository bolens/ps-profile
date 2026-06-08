<#
tests/unit/library-fragment-cache-path-error-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentCachePath error handling.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/fragment/FragmentCachePath.psm1') `
        -DisableNameChecking -Force -Global
}

Describe 'Fragment cache path error extended scenarios' {
    Context 'Get-FragmentCacheDbPath' {
        It 'Throws when the cache directory cannot be resolved' {
            InModuleScope -ModuleName FragmentCachePath {
                Mock Get-FragmentCacheDirectory { return $null }

                { Get-FragmentCacheDbPath } | Should -Throw '*Unable to determine fragment cache directory*'
            }
        }
    }

    Context 'Get-FragmentCacheDirectory' {
        AfterEach {
            if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
                Restore-AllMocks
            }
        }

        It 'Resolves relative PS_PROFILE_CACHE_DIR paths against the current location' {
            $tempRoot = New-TestTempDirectory -Prefix 'FragmentCacheRelative'
            $relativeCache = 'relative-cache-dir'
            $expectedCache = Join-Path $tempRoot $relativeCache

            try {
                Push-Location $tempRoot
                Mock-EnvironmentVariable -Name 'PS_PROFILE_CACHE_DIR' -Value $relativeCache

                Get-FragmentCacheDirectory | Should -Be $expectedCache
            }
            finally {
                Pop-Location -ErrorAction SilentlyContinue
                if (Test-Path -LiteralPath $tempRoot) {
                    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
