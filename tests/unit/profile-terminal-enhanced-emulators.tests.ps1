# ===============================================
# profile-terminal-enhanced-emulators.tests.ps1
# Unit tests for terminal emulator functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
}

Describe 'terminal-enhanced.ps1 - Terminal Emulator Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('alacritty', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('kitty', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('wezterm-nightly', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('wezterm', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('tabby', [ref]$null)
        }
    }
    
    Context 'Launch-Alacritty' {
        It 'Returns null when alacritty is not available' {
            Mock-CommandAvailabilityPester -CommandName 'alacritty' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'alacritty' } -MockWith { return $null }
            
            $result = Launch-Alacritty -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls alacritty when available' {
            Setup-AvailableCommandMock -CommandName 'alacritty'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Alacritty -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'alacritty'
        }
        
        It 'Calls alacritty with command when provided' {
            Setup-AvailableCommandMock -CommandName 'alacritty'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Alacritty -Command 'git status' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '-e'
            $script:capturedProcess.ArgumentList | Should -Contain 'git status'
        }
        
        It 'Calls alacritty with working directory when provided' {
            Setup-AvailableCommandMock -CommandName 'alacritty'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects' } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Alacritty -WorkingDirectory 'C:\Projects' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--working-directory'
            $script:capturedProcess.ArgumentList | Should -Contain 'C:\Projects'
        }
    }
    
    Context 'Launch-Kitty' {
        It 'Returns null when kitty is not available' {
            Mock-CommandAvailabilityPester -CommandName 'kitty' -Available $false
            
            $result = Launch-Kitty -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls kitty when available' {
            Setup-AvailableCommandMock -CommandName 'kitty'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Kitty -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'kitty'
        }
    }
    
    Context 'Launch-WezTerm' {
        It 'Returns null when WezTerm is not available' {
            Mock-CommandAvailabilityPester -CommandName 'wezterm-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'wezterm' -Available $false
            
            $result = Launch-WezTerm -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls wezterm-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'wezterm-nightly'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-WezTerm -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'wezterm-nightly'
        }
        
        It 'Falls back to wezterm when wezterm-nightly not available' {
            Mock-CommandAvailabilityPester -CommandName 'wezterm-nightly' -Available $false
            Setup-AvailableCommandMock -CommandName 'wezterm'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-WezTerm -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'wezterm'
        }
    }
    
    Context 'Launch-Tabby' {
        It 'Returns null when tabby is not available' {
            Mock-CommandAvailabilityPester -CommandName 'tabby' -Available $false
            
            $result = Launch-Tabby -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls tabby when available' {
            Setup-AvailableCommandMock -CommandName 'tabby'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Tabby -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'tabby'
        }
    }
}

