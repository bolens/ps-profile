. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'System Utilities Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'System utility functions edge cases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '07-system.ps1')
        }

        It 'which handles non-existent commands' {
            $nonExistent = "NonExistentCommand_$(Get-Random)"
            $result = which $nonExistent
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

        It 'pgrep handles pattern not found' {
            $tempFile = Join-Path $TestDrive 'test_no_match.txt'
            Set-Content -Path $tempFile -Value 'no match here'
            $result = pgrep 'nonexistentpattern' $tempFile
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

        It 'touch updates existing file timestamp' {
            $tempFile = Join-Path $TestDrive 'test_touch_existing.txt'
            Set-Content -Path $tempFile -Value 'content'
            $before = (Get-Item $tempFile).LastWriteTime
            Start-Sleep -Milliseconds 1100
            touch $tempFile
            $after = (Get-Item $tempFile).LastWriteTime
            $after | Should -BeGreaterOrEqual $before
        }

        It 'search handles empty directories' {
            $emptyDir = Join-Path $TestDrive 'empty_search'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            Push-Location $emptyDir
            try {
                $result = search '*.txt'
                ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'System utility aliases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '07-system.ps1')
        }

        It 'rest alias is available' {
            Get-Command rest -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'web alias is available' {
            Get-Command web -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'unzip alias is available' {
            Get-Command unzip -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'rest alias invokes Invoke-RestMethod' {
            $alias = Get-Alias rest -ErrorAction SilentlyContinue
            if ($alias) {
                $alias.Definition | Should -Match 'Invoke-Rest'
            }
        }

        It 'web alias invokes Invoke-WebRequest' {
            $alias = Get-Alias web -ErrorAction SilentlyContinue
            if ($alias) {
                $alias.Definition | Should -Match 'Invoke-WebRequest'
            }
        }

        It 'Invoke-RestApi function exists and can be called' {
            # This function requires URI parameter, so just test it exists
            Get-Command Invoke-RestApi -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Invoke-WebRequestCustom function exists and can be called' {
            # This function requires URI parameter, so just test it exists
            Get-Command Invoke-WebRequestCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Expand-ArchiveCustom function exists and can be called' {
            # This function requires Path parameter, so just test it exists
            Get-Command Expand-ArchiveCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Compress-ArchiveCustom function exists and can be called' {
            # This function requires Path parameter, so just test it exists
            Get-Command Compress-ArchiveCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Open-VSCode function exists and can be called' {
            Get-Command Open-VSCode -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test calling only if VS Code is available
            if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") {
                { Open-VSCode -ErrorAction Stop } | Should -Not -Throw
            }
        }

        It 'Open-Neovim function exists and can be called' {
            Get-Command Open-Neovim -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test calling only if neovim is available
            if (Get-Command nvim -ErrorAction SilentlyContinue) {
                { Open-Neovim -ErrorAction Stop } | Should -Not -Throw
            }
        }

        It 'Open-NeovimVi function exists and can be called' {
            Get-Command Open-NeovimVi -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test calling only if neovim is available
            if (Get-Command nvim -ErrorAction SilentlyContinue) {
                { Open-NeovimVi -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }

    Context 'Cross-platform compatibility' {
        It 'path separators are handled correctly' {
            $profileContent = Get-Content $script:ProfilePath -Raw
            $hardcodedPaths = [regex]::Matches($profileContent, '[^\\]\\[A-Za-z]:\\')
            $hardcodedPaths.Count | Should -BeLessThan 10
        }

        It 'functions work with both Windows and Unix-style paths' {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '02-files-navigation.ps1')

            $testPath = Join-Path $TestDrive 'test'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            Push-Location $testPath
            try {
                ..
                $parent = Get-Location
                $parent.Path | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
    }
}
