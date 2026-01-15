# ===============================================
# profile-editors-other.tests.ps1
# Unit tests for other editor functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'editors.ps1')
}

Describe 'editors.ps1 - Other Editor Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cursor', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('neovim-nightly', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('nvim', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('emacs', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('lapce-nightly', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('zed-nightly', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
        
        # Always mock Start-Process to prevent actual process launches
        # Individual tests can override this with more specific mocks
        Mock Start-Process -MockWith {
            # Default mock - just capture the call, don't launch anything
            return $null
        }
    }
    
    Context 'Edit-WithCursor' {
        It 'Returns null when cursor is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cursor' -Available $false
            
            $result = Edit-WithCursor -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls cursor when available' {
            Setup-AvailableCommandMock -CommandName 'cursor'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithCursor -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'cursor'
        }
        
        It 'Calls cursor with new window flag when provided' {
            Setup-AvailableCommandMock -CommandName 'cursor'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithCursor -NewWindow -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--new-window'
        }
        
        It 'Handles Start-Process errors gracefully for cursor' {
            Setup-AvailableCommandMock -CommandName 'cursor'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            Mock Start-Process -MockWith { throw "Process start failed" }
            
            { Edit-WithCursor -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Edit-WithNeovim' {
        It 'Returns null when Neovim is not available' {
            Mock-CommandAvailabilityPester -CommandName 'neovim-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'nvim' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'neovim' -Available $false
            
            $result = Edit-WithNeovim -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls neovim-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'neovim-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithNeovim -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'neovim-nightly'
        }
        
        It 'Uses GUI version when UseGui specified' {
            Setup-AvailableCommandMock -CommandName 'neovim-qt'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithNeovim -UseGui -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'neovim-qt'
        }
        
        It 'Falls back to nvim when neovim-nightly not available' {
            Mock-CommandAvailabilityPester -CommandName 'neovim-nightly' -Available $false
            Setup-AvailableCommandMock -CommandName 'nvim'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithNeovim -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'nvim'
        }
        
        It 'Handles Start-Process errors gracefully for neovim' {
            Setup-AvailableCommandMock -CommandName 'neovim-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            Mock Start-Process -MockWith { throw "Process start failed" }
            
            { Edit-WithNeovim -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Launch-Emacs' {
        It 'Returns null when emacs is not available' {
            Mock-CommandAvailabilityPester -CommandName 'emacs' -Available $false
            
            $result = Launch-Emacs -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls emacs when available' {
            Setup-AvailableCommandMock -CommandName 'emacs'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Emacs -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'emacs'
        }
        
        It 'Calls emacs with daemon flag when NoWindow specified' {
            Setup-AvailableCommandMock -CommandName 'emacs'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Emacs -NoWindow -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--daemon'
        }
        
        It 'Calls emacs with path when provided' {
            Setup-AvailableCommandMock -CommandName 'emacs'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'script.ps1' } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Emacs -Path 'script.ps1' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain 'script.ps1'
        }
        
        It 'Handles Start-Process errors gracefully for emacs' {
            Setup-AvailableCommandMock -CommandName 'emacs'
            Mock Start-Process -MockWith { throw "Process start failed" }
            
            { Launch-Emacs -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Launch-Lapce' {
        It 'Returns null when Lapce is not available' {
            Mock-CommandAvailabilityPester -CommandName 'lapce-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'lapce' -Available $false
            
            $result = Launch-Lapce -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls lapce-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'lapce-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Lapce -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'lapce-nightly'
        }
        
        It 'Falls back to lapce when lapce-nightly not available' {
            Mock-CommandAvailabilityPester -CommandName 'lapce-nightly' -Available $false
            Setup-AvailableCommandMock -CommandName 'lapce'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Lapce -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'lapce'
        }
        
        It 'Handles Start-Process errors gracefully for lapce' {
            Setup-AvailableCommandMock -CommandName 'lapce-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            Mock Start-Process -MockWith { throw "Process start failed" }
            
            { Launch-Lapce -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Launch-Zed' {
        It 'Returns null when Zed is not available' {
            Mock-CommandAvailabilityPester -CommandName 'zed-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'zed' -Available $false
            
            $result = Launch-Zed -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls zed-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'zed-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Zed -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'zed-nightly'
        }
        
        It 'Falls back to zed when zed-nightly not available' {
            Mock-CommandAvailabilityPester -CommandName 'zed-nightly' -Available $false
            Setup-AvailableCommandMock -CommandName 'zed'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Zed -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'zed'
        }
        
        It 'Handles Start-Process errors gracefully for zed' {
            Setup-AvailableCommandMock -CommandName 'zed-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            Mock Start-Process -MockWith { throw "Process start failed" }
            
            { Launch-Zed -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Get-EditorInfo' {
        It 'Returns empty array when no editors are available' {
            # Mock all commands as unavailable
            $allCommands = @('code-insiders', 'code', 'codium', 'cursor', 'neovim-nightly', 'nvim', 'emacs', 'lapce-nightly', 'zed-nightly')
            foreach ($cmd in $allCommands) {
                Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
            }
            
            $result = Get-EditorInfo
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns list of available editors' {
            Setup-AvailableCommandMock -CommandName 'code-insiders'
            Setup-AvailableCommandMock -CommandName 'cursor'
            Setup-AvailableCommandMock -CommandName 'neovim-nightly'
            
            $result = Get-EditorInfo
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            
            $vscode = $result | Where-Object { $_.Name -eq 'VS Code' }
            $vscode | Should -Not -BeNullOrEmpty
            $vscode.Command | Should -Be 'code-insiders'
            $vscode.Available | Should -Be $true
        }
        
        It 'Prefers preferred command variants' {
            Setup-AvailableCommandMock -CommandName 'lapce-nightly'
            Setup-AvailableCommandMock -CommandName 'lapce'
            
            $result = Get-EditorInfo
            
            $lapce = $result | Where-Object { $_.Name -eq 'Lapce' }
            $lapce | Should -Not -BeNullOrEmpty
            $lapce.Command | Should -Be 'lapce-nightly'
        }
    }
}

