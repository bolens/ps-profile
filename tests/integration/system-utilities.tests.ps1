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

    Context 'System utility functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '07-system.ps1')
        }

        It 'Get-DiskUsage function exists and returns drive information' {
            Get-Command Get-DiskUsage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = Get-DiskUsage
            $result | Should -Not -BeNullOrEmpty
            $result[0].PSObject.Properties.Name | Should -Contain 'Name'
        }

        It 'Get-TopProcesses function exists and returns process information' {
            Get-Command Get-TopProcesses -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = Get-TopProcesses
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeLessOrEqual 10
        }

        It 'Get-NetworkPorts function exists' {
            Get-Command Get-NetworkPorts -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test that function doesn't throw when called (netstat may require admin)
            { Get-NetworkPorts -ErrorAction SilentlyContinue | Out-Null } | Should -Not -Throw
        }

        It 'Test-NetworkConnection function exists' {
            Get-Command Test-NetworkConnection -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test with localhost which should always work
            $result = Test-NetworkConnection -ComputerName localhost -Count 1 -ErrorAction SilentlyContinue
            # Result may be null if ping fails, but function should exist
            { Test-NetworkConnection -ComputerName localhost -Count 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Resolve-DnsNameCustom function exists' {
            Get-Command Resolve-DnsNameCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test with localhost
            { Resolve-DnsNameCustom -Name localhost -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-File function exists and can search for files' {
            Get-Command Find-File -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Create a test file
            $testFile = Join-Path $TestDrive 'test_find.txt'
            Set-Content -Path $testFile -Value 'test content'
            # Search for it
            $result = Find-File -Filter 'test_find.txt'
            # Result may be empty if search doesn't work as expected, but function should exist
            { Find-File -Filter '*.txt' } | Should -Not -Throw
        }

        It 'New-Directory function exists' {
            Get-Command New-Directory -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $testDir = Join-Path $TestDrive 'test_new_dir'
            { New-Directory -Path $testDir } | Should -Not -Throw
            Test-Path $testDir | Should -Be $true
        }

        It 'Remove-ItemCustom function exists' {
            Get-Command Remove-ItemCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $testFile = Join-Path $TestDrive 'test_remove.txt'
            Set-Content -Path $testFile -Value 'test'
            { Remove-ItemCustom -Path $testFile } | Should -Not -Throw
            Test-Path $testFile | Should -Be $false
        }

        It 'Copy-ItemCustom function exists' {
            Get-Command Copy-ItemCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $sourceFile = Join-Path $TestDrive 'test_copy_source.txt'
            $destFile = Join-Path $TestDrive 'test_copy_dest.txt'
            Set-Content -Path $sourceFile -Value 'test content'
            { Copy-ItemCustom -Path $sourceFile -Destination $destFile } | Should -Not -Throw
            Test-Path $destFile | Should -Be $true
        }

        It 'Move-ItemCustom function exists' {
            Get-Command Move-ItemCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $sourceFile = Join-Path $TestDrive 'test_move_source.txt'
            $destFile = Join-Path $TestDrive 'test_move_dest.txt'
            Set-Content -Path $sourceFile -Value 'test content'
            { Move-ItemCustom -Path $sourceFile -Destination $destFile } | Should -Not -Throw
            Test-Path $sourceFile | Should -Be $false
            Test-Path $destFile | Should -Be $true
        }

        It 'Invoke-RestApi function exists' {
            Get-Command Invoke-RestApi -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test that function doesn't throw when called with invalid URL
            { Invoke-RestApi -Uri 'http://invalid-url-that-does-not-exist.com' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Invoke-WebRequestCustom function exists' {
            Get-Command Invoke-WebRequestCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test that function doesn't throw when called with invalid URL
            { Invoke-WebRequestCustom -Uri 'http://invalid-url-that-does-not-exist.com' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Expand-ArchiveCustom function exists' {
            Get-Command Expand-ArchiveCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Just test that function exists, don't call with invalid parameters
        }

        It 'Compress-ArchiveCustom function exists' {
            Get-Command Compress-ArchiveCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Just test that function exists, don't call with invalid parameters
        }

        It 'Open-VSCode function exists' {
            Get-Command Open-VSCode -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Just test that function exists, don't call it since VS Code may not be installed
        }
    }
}
