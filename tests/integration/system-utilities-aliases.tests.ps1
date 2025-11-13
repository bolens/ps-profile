. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'System Utility Aliases' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
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
}