. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Package Manager Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'Scoop package manager functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '09-package-managers.ps1')
        }

        It 'Install-ScoopPackage function exists when scoop is available' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Get-Command Install-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Find-ScoopPackage function exists when scoop is available' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Get-Command Find-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Update-ScoopPackage function exists when scoop is available' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Get-Command Update-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Uninstall-ScoopPackage function exists when scoop is available' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Get-Command Uninstall-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Get-ScoopPackage function exists when scoop is available' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Get-Command Get-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Get-ScoopPackageInfo function exists when scoop is available' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Get-Command Get-ScoopPackageInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Clear-ScoopCache function exists when scoop is available' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Get-Command Clear-ScoopCache -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }
    }

    Context 'UV package manager functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '09-package-managers.ps1')
        }

        It 'Install-UVTool function exists when uv is available' {
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                Get-Command Install-UVTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Invoke-UVRun function exists when uv is available' {
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                Get-Command Invoke-UVRun -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Invoke-UVTool function exists when uv is available' {
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                Get-Command Invoke-UVTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Add-UVDependency function exists when uv is available' {
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                Get-Command Add-UVDependency -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Sync-UVDependencies function exists when uv is available' {
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                Get-Command Sync-UVDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }
    }

    Context 'PNPM package manager functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '09-package-managers.ps1')
        }

        It 'Install-PnpmPackage function exists when pnpm is available' {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Get-Command Install-PnpmPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Add-PnpmPackage function exists when pnpm is available' {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Get-Command Add-PnpmPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Add-PnpmDevPackage function exists when pnpm is available' {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Get-Command Add-PnpmDevPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Invoke-PnpmScript function exists when pnpm is available' {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Get-Command Invoke-PnpmScript -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Start-PnpmProject function exists when pnpm is available' {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Get-Command Start-PnpmProject -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Build-PnpmProject function exists when pnpm is available' {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Get-Command Build-PnpmProject -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Test-PnpmProject function exists when pnpm is available' {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Get-Command Test-PnpmProject -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Start-PnpmDev function exists when pnpm is available' {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Get-Command Start-PnpmDev -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }
    }
}
