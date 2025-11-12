. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'File Operations Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
    }

    Context 'File listing functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-listing.ps1')
        }

        It 'Get-ChildItemDetailed (ll) function is available' {
            Get-Command ll -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-ChildItemDetailed -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ChildItemAll (la) function is available' {
            Get-Command la -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-ChildItemAll -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ChildItemVisible (lx) function is available' {
            Get-Command lx -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-ChildItemVisible -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-DirectoryTree (tree) function is available' {
            Get-Command tree -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-DirectoryTree -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-FileContent (bat-cat) function is available' {
            Get-Command bat-cat -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Show-FileContent -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'll function lists directory contents' {
            $testDir = Join-Path $TestDrive 'test_listing'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $testDir 'test.txt') -Force | Out-Null

            Push-Location $testDir
            try {
                $result = ll
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'tree function displays directory structure' {
            $testDir = Join-Path $TestDrive 'test_tree'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $testDir 'subdir') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $testDir 'file.txt') -Force | Out-Null

            Push-Location $testDir
            try {
                $result = tree
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Show-FileContent handles file input' {
            $testFile = Join-Path $TestDrive 'test_content.txt'
            Set-Content -Path $testFile -Value 'test content'

            { Show-FileContent $testFile } | Should -Not -Throw
        }
    }

    Context 'File navigation functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-navigation.ps1')
        }

        It '.. function navigates up one directory' {
            $testDir = Join-Path $TestDrive 'level1\level2'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                $before = Get-Location
                ..
                $after = Get-Location
                $after.Path | Should -Match ([regex]::Escape((Split-Path $before.Path)))
            }
            finally {
                Pop-Location
            }
        }

        It '... function navigates up two directories' {
            $testDir = Join-Path $TestDrive 'level1\level2\level3'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                $before = Get-Location
                ...
                $after = Get-Location
                $beforeParent = Split-Path (Split-Path $before.Path)
                $after.Path | Should -Match ([regex]::Escape($beforeParent))
            }
            finally {
                Pop-Location
            }
        }

        It '.... function navigates up three directories' {
            $testDir = Join-Path $TestDrive 'level1\level2\level3\level4'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                $before = Get-Location
                ....
                $after = Get-Location
                $beforeParent = Split-Path (Split-Path (Split-Path $before.Path))
                $after.Path | Should -Match ([regex]::Escape($beforeParent))
            }
            finally {
                Pop-Location
            }
        }

        It '~ function navigates to home directory' {
            $originalLocation = Get-Location
            try {
                ~
                $homeLocation = Get-Location
                $homeLocation.Path | Should -Match ([regex]::Escape($env:USERPROFILE))
            }
            finally {
                Set-Location $originalLocation
            }
        }

        It 'desktop alias navigates to Desktop' {
            if (Test-Path "$env:USERPROFILE\Desktop") {
                $originalLocation = Get-Location
                try {
                    desktop
                    $desktop = Get-Location
                    $desktop.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Desktop"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }

        It 'downloads alias navigates to Downloads' {
            if (Test-Path "$env:USERPROFILE\Downloads") {
                $originalLocation = Get-Location
                try {
                    downloads
                    $downloads = Get-Location
                    $downloads.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Downloads"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }

        It 'docs alias navigates to Documents' {
            if (Test-Path "$env:USERPROFILE\Documents") {
                $originalLocation = Get-Location
                try {
                    docs
                    $docs = Get-Location
                    $docs.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Documents"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }
    }

    Context 'Lazy loading patterns' {
        It 'Ensure-FileListing initializes on first use' {
            . (Join-Path $script:ProfileDir '02-files-listing.ps1')

            $before = Test-Path Function:\Get-ChildItemDetailed
            if (-not $before) {
                $testDir = Join-Path $TestDrive 'lazy_test'
                New-Item -ItemType Directory -Path $testDir -Force | Out-Null
                Push-Location $testDir
                try {
                    ll | Out-Null
                    $after = Test-Path Function:\Get-ChildItemDetailed
                    $after | Should -Be $true
                }
                finally {
                    Pop-Location
                }
            }
        }

        It 'Ensure-FileNavigation initializes on first use' {
            . (Join-Path $script:ProfileDir '02-files-navigation.ps1')

            $before = Test-Path Function:\..
            if (-not $before) {
                ..
                $after = Test-Path Function:\..
                $after | Should -Be $true
            }
        }
    }
}
