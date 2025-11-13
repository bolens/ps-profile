. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'File Lazy Loading Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
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
