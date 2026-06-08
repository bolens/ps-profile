<#
tests/unit/library-platform-paths.tests.ps1

.SYNOPSIS
    Unit tests for PlatformPaths cross-platform directory helpers.
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

    $script:TempRoot = New-TestTempDirectory -Prefix 'PlatformPathsTests'
}

AfterAll {
    Remove-Module PlatformPaths -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PlatformPaths Module Functions' {
    Context 'Get-TempDirectory' {
        It 'Returns a non-empty path' {
            Get-TempDirectory | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ConfigDirectory' {
        It 'Returns a path when HOME is available' {
            if ($env:HOME -or $env:USERPROFILE) {
                Get-ConfigDirectory | Should -Not -BeNullOrEmpty
            }
            else {
                Set-ItResult -Skipped -Because 'HOME and USERPROFILE are unset'
            }
        }
    }

    Context 'Get-CacheDirectory' {
        It 'Returns a path with the default application name' {
            Get-CacheDirectory | Should -Not -BeNullOrEmpty
        }

        It 'Appends a custom application name to the cache root' {
            $originalXdgCache = $env:XDG_CACHE_HOME
            $customCacheRoot = Join-Path $script:TempRoot 'cache-root'

            try {
                Remove-Item Env:PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                $env:XDG_CACHE_HOME = $customCacheRoot

                Get-CacheDirectory -ApplicationName 'custom-app' |
                    Should -Be (Join-Path $customCacheRoot 'custom-app')
            }
            finally {
                $env:XDG_CACHE_HOME = $originalXdgCache
            }
        }
    }

    Context 'Get-DataDirectory' {
        It 'Returns the data root when ApplicationName is omitted' {
            $originalXdgData = $env:XDG_DATA_HOME
            $customDataRoot = Join-Path $script:TempRoot 'data-root'

            try {
                Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                $env:XDG_DATA_HOME = $customDataRoot

                Get-DataDirectory | Should -Be $customDataRoot
            }
            finally {
                $env:XDG_DATA_HOME = $originalXdgData
            }
        }
    }

    Context 'Get-UserDirectory' {
        It 'Falls back to a path under HOME when XDG overrides are absent' {
            $fakeHome = Join-Path $script:TempRoot 'user-home'
            New-Item -ItemType Directory -Path $fakeHome -Force | Out-Null
            $originalHome = $env:HOME
            $originalDesktop = $env:XDG_DESKTOP_DIR

            try {
                Remove-Item Env:XDG_DESKTOP_DIR -ErrorAction SilentlyContinue
                Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                $env:HOME = $fakeHome

                Get-UserDirectory -Name 'Desktop' | Should -Be (Join-Path $fakeHome 'Desktop')
            }
            finally {
                $env:HOME = $originalHome
                $env:XDG_DESKTOP_DIR = $originalDesktop
            }
        }
    }

    Context 'Get-WranglerConfigPaths' {
        It 'Returns Dir and File keys for a resolved config directory' {
            $originalXdgConfig = $env:XDG_CONFIG_HOME
            $customConfig = Join-Path $script:TempRoot 'wrangler-config'

            try {
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                $env:XDG_CONFIG_HOME = $customConfig

                $paths = Get-WranglerConfigPaths
                $paths.Keys | Should -Contain 'Dir'
                $paths.Keys | Should -Contain 'File'
                $paths.Dir | Should -Be (Join-Path $customConfig '.wrangler' 'config')
            }
            finally {
                $env:XDG_CONFIG_HOME = $originalXdgConfig
            }
        }
    }
}
