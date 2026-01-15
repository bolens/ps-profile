# ===============================================
# profile-terminal-enhanced-multiplexer.tests.ps1
# Unit tests for terminal multiplexer functions
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

Describe 'terminal-enhanced.ps1 - Multiplexer Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('tmux', [ref]$null)
        }
    }
    
    Context 'Start-Tmux' {
        It 'Returns null when tmux is not available' {
            Mock-CommandAvailabilityPester -CommandName 'tmux' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'tmux' } -MockWith { return $null }
            
            $result = Start-Tmux -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Creates new tmux session when no session name provided' {
            Setup-AvailableCommandMock -CommandName 'tmux'
            
            $script:capturedArgs = @()
            Mock -CommandName 'tmux' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Session created'
            }
            
            Start-Tmux -ErrorAction SilentlyContinue
            
            Should -Invoke 'tmux' -Times 2 -Exactly
            $script:capturedArgs | Should -Contain 'new-session'
            $script:capturedArgs | Should -Contain '-d'
        }
        
        It 'Creates named tmux session' {
            Setup-AvailableCommandMock -CommandName 'tmux'
            
            $script:capturedArgs = @()
            Mock -CommandName 'tmux' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Session created'
            }
            
            $result = Start-Tmux -SessionName 'dev' -ErrorAction SilentlyContinue
            
            Should -Invoke 'tmux' -Times 2 -Exactly
            $script:capturedArgs | Should -Contain 'new-session'
            $script:capturedArgs | Should -Contain '-s'
            $script:capturedArgs | Should -Contain 'dev'
            $result | Should -Be 'dev'
        }
        
        It 'Attaches to existing session when Attach specified' {
            Setup-AvailableCommandMock -CommandName 'tmux'
            
            $script:capturedArgs = @()
            Mock -CommandName 'tmux' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                if ($args[0] -eq 'list-sessions') {
                    return 'dev: 1 windows'
                }
                return 'Session attached'
            }
            
            $result = Start-Tmux -SessionName 'dev' -Attach -ErrorAction SilentlyContinue
            
            Should -Invoke 'tmux' -Times 2 -Exactly
            $script:capturedArgs | Should -Contain 'attach-session'
            $result | Should -Be 'dev'
        }
        
        It 'Creates new session when Attach specified but session does not exist' {
            Setup-AvailableCommandMock -CommandName 'tmux'
            
            $script:capturedArgs = @()
            Mock -CommandName 'tmux' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                if ($args[0] -eq 'list-sessions') {
                    return ''
                }
                return 'Session created'
            }
            
            $result = Start-Tmux -SessionName 'dev' -Attach -ErrorAction SilentlyContinue
            
            Should -Invoke 'tmux' -Times 2 -Exactly
            $script:capturedArgs | Should -Contain 'new-session'
            $result | Should -Be 'dev'
        }
        
        It 'Executes command in new session' {
            Setup-AvailableCommandMock -CommandName 'tmux'
            
            $script:capturedArgs = @()
            Mock -CommandName 'tmux' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Session created'
            }
            
            Start-Tmux -SessionName 'dev' -Command 'npm start' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'npm start'
        }
    }
    
    Context 'Get-TerminalInfo' {
        It 'Returns empty array when no terminals are available' {
            # Mock all commands as unavailable
            $allCommands = @('alacritty', 'kitty', 'wezterm-nightly', 'wezterm', 'tabby', 'tmux')
            foreach ($cmd in $allCommands) {
                Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
            }
            
            $result = Get-TerminalInfo
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns list of available terminals' {
            Setup-AvailableCommandMock -CommandName 'alacritty'
            Setup-AvailableCommandMock -CommandName 'kitty'
            Setup-AvailableCommandMock -CommandName 'tmux'
            
            $result = Get-TerminalInfo
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            
            $alacritty = $result | Where-Object { $_.Name -eq 'Alacritty' }
            $alacritty | Should -Not -BeNullOrEmpty
            $alacritty.Command | Should -Be 'alacritty'
            $alacritty.Available | Should -Be $true
        }
        
        It 'Prefers preferred command variants' {
            Setup-AvailableCommandMock -CommandName 'wezterm-nightly'
            Setup-AvailableCommandMock -CommandName 'wezterm'
            
            $result = Get-TerminalInfo
            
            $wezterm = $result | Where-Object { $_.Name -eq 'WezTerm' }
            $wezterm | Should -Not -BeNullOrEmpty
            $wezterm.Command | Should -Be 'wezterm-nightly'
        }
    }
}

