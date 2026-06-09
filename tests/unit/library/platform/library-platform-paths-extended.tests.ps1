<#
tests/unit/library-platform-paths-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PlatformPaths cross-platform directory helpers.
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
    $platformPathsModule = Get-TestPath -RelativePath 'scripts\lib\core\PlatformPaths.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $platformPathsModule -DisableNameChecking -ErrorAction Stop

    $script:TempRoot = New-TestTempDirectory -Prefix 'PlatformPathsExtended'
}

AfterAll {
    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PlatformPaths extended scenarios' {
    Context 'Get-TempDirectory' {
        It 'Prefers TEMP over the system fallback' {
            $originalTemp = $env:TEMP
            $customTemp = Join-Path $script:TempRoot 'custom-temp'

                        $env:TEMP = $customTemp
            Get-TempDirectory | Should -Be $customTemp
        }
        finally {
            $env:TEMP = $originalTemp
        }

        It 'Uses TMPDIR when TEMP is not set' {
            $originalTemp = $env:TEMP
            $originalTmpDir = $env:TMPDIR
            $customTmpDir = Join-Path $script:TempRoot 'custom-tmpdir'

                        Remove-Item Env:TEMP -ErrorAction SilentlyContinue
            $env:TMPDIR = $customTmpDir
            Get-TempDirectory | Should -Be $customTmpDir
        }
        finally {
            if ($null -ne $originalTemp) { $env:TEMP = $originalTemp }
            $env:TMPDIR = $originalTmpDir
        }
    }

    Context 'Get-ConfigDirectory and Get-CacheDirectory' {
        It 'Uses XDG_CONFIG_HOME when configured' {
            $original = $env:XDG_CONFIG_HOME
            $customConfig = Join-Path $script:TempRoot 'xdg-config'

                        $env:XDG_CONFIG_HOME = $customConfig
            Get-ConfigDirectory | Should -Be $customConfig
        }
        finally {
            $env:XDG_CONFIG_HOME = $original
        }

        It 'Honors PS_PROFILE_CACHE_DIR override' {
            $original = $env:PS_PROFILE_CACHE_DIR
            $customCache = Join-Path $script:TempRoot 'profile-cache'

                        $env:PS_PROFILE_CACHE_DIR = $customCache
            Get-CacheDirectory | Should -Be $customCache
        }
        finally {
            $env:PS_PROFILE_CACHE_DIR = $original
        }

        It 'Builds cache path under XDG_CACHE_HOME when no override exists' {
            $originalCacheOverride = $env:PS_PROFILE_CACHE_DIR
            $originalLocalAppData = $env:LOCALAPPDATA
            $originalXdgCache = $env:XDG_CACHE_HOME
            $customXdgCache = Join-Path $script:TempRoot 'xdg-cache'

            try {
                Remove-Item Env:PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                $env:XDG_CACHE_HOME = $customXdgCache

                Get-CacheDirectory -ApplicationName 'test-app' |
                    Should -Be (Join-Path $customXdgCache 'test-app')
            }
            finally {
                if ($null -ne $originalCacheOverride) { $env:PS_PROFILE_CACHE_DIR = $originalCacheOverride }
                if ($null -ne $originalLocalAppData) { $env:LOCALAPPDATA = $originalLocalAppData }
                $env:XDG_CACHE_HOME = $originalXdgCache
            }
        }
    }

    Context 'Get-DataDirectory and Get-WranglerConfigPaths' {
        It 'Appends application name under the data root' {
            $originalXdgData = $env:XDG_DATA_HOME
            $customDataRoot = Join-Path $script:TempRoot 'xdg-data'

            try {
                Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                $env:XDG_DATA_HOME = $customDataRoot

                Get-DataDirectory -ApplicationName 'ps-profile' |
                    Should -Be (Join-Path $customDataRoot 'ps-profile')
            }
            finally {
                $env:XDG_DATA_HOME = $originalXdgData
            }
        }

        It 'Returns Wrangler config directory and default file path' {
            $originalXdgConfig = $env:XDG_CONFIG_HOME
            $originalAppData = $env:APPDATA
            $customConfig = Join-Path $script:TempRoot 'wrangler-config-root'

            try {
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                $env:XDG_CONFIG_HOME = $customConfig

                $paths = Get-WranglerConfigPaths

                $paths.Dir | Should -Be (Join-Path $customConfig '.wrangler' 'config')
                $paths.File | Should -Be (Join-Path $customConfig '.wrangler' 'config' 'default.toml')
            }
            finally {
                $env:XDG_CONFIG_HOME = $originalXdgConfig
                if ($null -ne $originalAppData) { $env:APPDATA = $originalAppData }
            }
        }
    }
}
