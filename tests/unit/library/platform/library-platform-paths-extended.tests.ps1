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

            try {
                $env:TEMP = $customTemp
                Get-TempDirectory | Should -Be $customTemp
            }
            finally {
                $env:TEMP = $originalTemp
            }
        }

        It 'Uses TMPDIR when TEMP is not set' {
            $originalTemp = $env:TEMP
            $originalTmpDir = $env:TMPDIR
            $customTmpDir = Join-Path $script:TempRoot 'custom-tmpdir'

            try {
                Remove-Item Env:TEMP -ErrorAction SilentlyContinue
                $env:TMPDIR = $customTmpDir
                Get-TempDirectory | Should -Be $customTmpDir
            }
            finally {
                if ($null -ne $originalTemp) { $env:TEMP = $originalTemp }
                $env:TMPDIR = $originalTmpDir
            }
        }
    }

    Context 'Get-ConfigDirectory and Get-CacheDirectory' {
        It 'Uses XDG_CONFIG_HOME when configured' {
            $original = $env:XDG_CONFIG_HOME
            $customConfig = Join-Path $script:TempRoot 'xdg-config'

            try {
                $env:XDG_CONFIG_HOME = $customConfig
                Get-ConfigDirectory | Should -Be $customConfig
            }
            finally {
                $env:XDG_CONFIG_HOME = $original
            }
        }

        It 'Honors PS_PROFILE_CACHE_DIR override' {
            $original = $env:PS_PROFILE_CACHE_DIR
            $customCache = Join-Path $script:TempRoot 'profile-cache'

            try {
                $env:PS_PROFILE_CACHE_DIR = $customCache
                Get-CacheDirectory | Should -Be $customCache
            }
            finally {
                $env:PS_PROFILE_CACHE_DIR = $original
            }
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

    Context 'PlatformPaths test environment hooks' {
        It 'Uses APPDATA for config when XDG_CONFIG_HOME is unset' {
            $originalXdg = $env:XDG_CONFIG_HOME
            $originalAppData = $env:APPDATA
            $customAppData = Join-Path $script:TempRoot 'app-data-config'

            try {
                Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
                $env:APPDATA = $customAppData
                Get-ConfigDirectory | Should -Be $customAppData
            }
            finally {
                $env:XDG_CONFIG_HOME = $originalXdg
                if ($null -eq $originalAppData) {
                    Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                }
                else {
                    $env:APPDATA = $originalAppData
                }
            }
        }

        It 'Uses LOCALAPPDATA for cache when higher-priority overrides are absent' {
            $originalOverride = $env:PS_PROFILE_CACHE_DIR
            $originalLocal = $env:LOCALAPPDATA
            $customLocal = Join-Path $script:TempRoot 'local-app-data'

            try {
                Remove-Item Env:PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                Remove-Item Env:XDG_CACHE_HOME -ErrorAction SilentlyContinue
                $env:LOCALAPPDATA = $customLocal
                Get-CacheDirectory -ApplicationName 'win-app' |
                    Should -Be (Join-Path $customLocal 'win-app')
            }
            finally {
                if ($null -eq $originalOverride) {
                    Remove-Item Env:PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_CACHE_DIR = $originalOverride
                }

                if ($null -eq $originalLocal) {
                    Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                }
                else {
                    $env:LOCALAPPDATA = $originalLocal
                }
            }
        }

        It 'Falls back to the system temp directory when user home is unavailable' {
            $originalFlag = $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME
            $originalOverride = $env:PS_PROFILE_CACHE_DIR
            $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME = '1'

            try {
                Remove-Item Env:PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                Remove-Item Env:XDG_CACHE_HOME -ErrorAction SilentlyContinue

                $expected = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile'
                Get-CacheDirectory | Should -Be $expected
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME = $originalFlag
                }

                if ($null -eq $originalOverride) {
                    Remove-Item Env:PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_CACHE_DIR = $originalOverride
                }
            }
        }

        It 'Returns null for data directory when no data root can be resolved' {
            $originalFlag = $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME
            $originalXdgData = $env:XDG_DATA_HOME
            $originalLocal = $env:LOCALAPPDATA
            $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME = '1'

            try {
                Remove-Item Env:XDG_DATA_HOME -ErrorAction SilentlyContinue
                Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                Get-DataDirectory | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME = $originalFlag
                }

                $env:XDG_DATA_HOME = $originalXdgData
                if ($null -eq $originalLocal) {
                    Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                }
                else {
                    $env:LOCALAPPDATA = $originalLocal
                }
            }
        }

        It 'Reads XDG user directory paths from user-dirs.dirs' {
            $fakeHome = Join-Path $script:TempRoot 'xdg-user-home'
            $configDir = Join-Path $fakeHome '.config'
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            @'
XDG_DOWNLOAD_DIR="$HOME/Downloads"
'@ | Set-Content -LiteralPath (Join-Path $configDir 'user-dirs.dirs') -Encoding UTF8

            $originalXdgConfig = $env:XDG_CONFIG_HOME
            $originalXdgDownloads = $env:XDG_DOWNLOAD_DIR
            $originalForcedHome = $env:PS_PROFILE_PLATFORM_PATHS_FORCE_USER_HOME

            try {
                Remove-Item Env:XDG_DOWNLOAD_DIR -ErrorAction SilentlyContinue
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                $env:XDG_CONFIG_HOME = $configDir
                $env:PS_PROFILE_PLATFORM_PATHS_FORCE_USER_HOME = $fakeHome
                Get-UserDirectory -Name 'Downloads' | Should -Be (Join-Path $fakeHome 'Downloads')
            }
            finally {
                $env:XDG_CONFIG_HOME = $originalXdgConfig
                $env:XDG_DOWNLOAD_DIR = $originalXdgDownloads
                if ($null -eq $originalForcedHome) {
                    Remove-Item Env:PS_PROFILE_PLATFORM_PATHS_FORCE_USER_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PLATFORM_PATHS_FORCE_USER_HOME = $originalForcedHome
                }
            }
        }

        It 'Resolves user home from USERPROFILE when HOME is unset' {
            $fakeProfile = Join-Path $script:TempRoot 'user-profile-home'
            New-Item -ItemType Directory -Path $fakeProfile -Force | Out-Null
            $originalHome = $env:HOME
            $originalProfile = $env:USERPROFILE

            try {
                Remove-Item Env:HOME -ErrorAction SilentlyContinue
                $env:USERPROFILE = $fakeProfile
                Get-ConfigDirectory | Should -Be (Join-Path $fakeProfile '.config')
            }
            finally {
                if ($null -eq $originalHome) {
                    Remove-Item Env:HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:HOME = $originalHome
                }

                if ($null -eq $originalProfile) {
                    Remove-Item Env:USERPROFILE -ErrorAction SilentlyContinue
                }
                else {
                    $env:USERPROFILE = $originalProfile
                }
            }
        }

        It 'Throws when Wrangler config directory cannot be resolved' {
            $originalFlag = $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME
            $originalXdg = $env:XDG_CONFIG_HOME
            $originalAppData = $env:APPDATA
            $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME = '1'

            try {
                Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                { Get-WranglerConfigPaths } | Should -Throw '*Unable to determine config directory*'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME = $originalFlag
                }

                $env:XDG_CONFIG_HOME = $originalXdg
                if ($null -eq $originalAppData) {
                    Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                }
                else {
                    $env:APPDATA = $originalAppData
                }
            }
        }

        It 'Uses LOCALAPPDATA for data directory when XDG_DATA_HOME is unset' {
            $originalXdgData = $env:XDG_DATA_HOME
            $originalLocal = $env:LOCALAPPDATA
            $customLocal = Join-Path $script:TempRoot 'local-data-root'

            try {
                Remove-Item Env:XDG_DATA_HOME -ErrorAction SilentlyContinue
                $env:LOCALAPPDATA = $customLocal

                Get-DataDirectory -ApplicationName 'profile-data' |
                    Should -Be (Join-Path $customLocal 'profile-data')
            }
            finally {
                $env:XDG_DATA_HOME = $originalXdgData
                if ($null -eq $originalLocal) {
                    Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                }
                else {
                    $env:LOCALAPPDATA = $originalLocal
                }
            }
        }

        It 'Returns data root without application suffix when ApplicationName is omitted' {
            $originalXdgData = $env:XDG_DATA_HOME
            $customDataRoot = Join-Path $script:TempRoot 'bare-data-root'

            try {
                Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue
                $env:XDG_DATA_HOME = $customDataRoot
                Get-DataDirectory | Should -Be $customDataRoot
            }
            finally {
                $env:XDG_DATA_HOME = $originalXdgData
            }
        }

        It 'Uses the Windows AppData layout for Wrangler config paths' {
            $originalAppData = $env:APPDATA
            $originalXdg = $env:XDG_CONFIG_HOME
            $customAppData = Join-Path $script:TempRoot 'windows-appdata'

            try {
                Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
                $env:APPDATA = $customAppData

                $paths = Get-WranglerConfigPaths
                $paths.Dir | Should -Be (Join-Path $customAppData 'xdg.config' '.wrangler' 'config')
            }
            finally {
                if ($null -eq $originalAppData) {
                    Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                }
                else {
                    $env:APPDATA = $originalAppData
                }

                $env:XDG_CONFIG_HOME = $originalXdg
            }
        }
    }
}
