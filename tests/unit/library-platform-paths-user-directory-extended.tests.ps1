<#
tests/unit/library-platform-paths-user-directory-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PlatformPaths user directory resolution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $platformPathsModule = Get-TestPath -RelativePath 'scripts\lib\core\PlatformPaths.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $platformPathsModule -DisableNameChecking -ErrorAction Stop

    $script:TempRoot = New-TestTempDirectory -Prefix 'PlatformPathsUserDir'
    $script:SavedHome = $env:HOME
    $script:SavedUserProfile = $env:USERPROFILE
    $script:SavedXdgConfigHome = $env:XDG_CONFIG_HOME
    $script:SavedXdgDesktopDir = $env:XDG_DESKTOP_DIR
    $script:SavedXdgDocumentsDir = $env:XDG_DOCUMENTS_DIR
    $script:SavedAppData = $env:APPDATA
}

AfterAll {
    $env:HOME = $script:SavedHome
    $env:USERPROFILE = $script:SavedUserProfile
    $env:XDG_CONFIG_HOME = $script:SavedXdgConfigHome
    $env:XDG_DESKTOP_DIR = $script:SavedXdgDesktopDir
    $env:XDG_DOCUMENTS_DIR = $script:SavedXdgDocumentsDir
    $env:APPDATA = $script:SavedAppData

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PlatformPaths user directory extended scenarios' {
    Context 'Get-UserDirectory' {
        It 'Uses XDG environment variables when configured' {
            $customDesktop = Join-Path $script:TempRoot 'xdg-desktop'
            $customDocuments = Join-Path $script:TempRoot 'xdg-documents'

            try {
                Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                $env:XDG_DESKTOP_DIR = $customDesktop
                $env:XDG_DOCUMENTS_DIR = $customDocuments

                Get-UserDirectory -Name 'Desktop' | Should -Be $customDesktop
                Get-UserDirectory -Name 'Documents' | Should -Be $customDocuments
            }
            finally {
                $env:XDG_DESKTOP_DIR = $script:SavedXdgDesktopDir
                $env:XDG_DOCUMENTS_DIR = $script:SavedXdgDocumentsDir
            }
        }

        It 'Reads user directory paths from user-dirs.dirs configuration' {
            $configHome = Join-Path $script:TempRoot 'config-home'
            $fakeHome = Join-Path $script:TempRoot 'fake-home'
            New-Item -ItemType Directory -Path $configHome -Force | Out-Null
            New-Item -ItemType Directory -Path $fakeHome -Force | Out-Null

            $userDirsFile = Join-Path $configHome 'user-dirs.dirs'
            Set-Content -LiteralPath $userDirsFile -Value 'XDG_DESKTOP_DIR="$HOME/ConfiguredDesktop"' -Encoding UTF8

            try {
                Remove-Item Env:XDG_DESKTOP_DIR -ErrorAction SilentlyContinue
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                $env:XDG_CONFIG_HOME = $configHome
                $env:HOME = $fakeHome

                Get-UserDirectory -Name 'Desktop' | Should -Be (Join-Path $fakeHome 'ConfiguredDesktop')
            }
            finally {
                $env:HOME = $script:SavedHome
                $env:XDG_CONFIG_HOME = $script:SavedXdgConfigHome
            }
        }

        It 'Resolves user directories under HOME when XDG overrides are absent' {
            $fakeHome = Join-Path $script:TempRoot 'fallback-home'
            New-Item -ItemType Directory -Path $fakeHome -Force | Out-Null

            try {
                Remove-Item Env:XDG_DOWNLOAD_DIR -ErrorAction SilentlyContinue
                Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
                $env:HOME = $fakeHome

                $result = Get-UserDirectory -Name 'Downloads'
                $result | Should -Not -BeNullOrEmpty
                $result.Replace('\', '/') | Should -Match ([regex]::Escape($fakeHome.Replace('\', '/')))
            }
            finally {
                $env:HOME = $script:SavedHome
            }
        }
    }

    Context 'Get-WranglerConfigPaths error handling' {
        It 'Throws when no config directory can be resolved' {
            InModuleScope -ModuleName PlatformPaths {
                Mock Get-ConfigDirectory { return $null }

                { Get-WranglerConfigPaths } | Should -Throw '*Unable to determine config directory*'
            }
        }
    }
}
