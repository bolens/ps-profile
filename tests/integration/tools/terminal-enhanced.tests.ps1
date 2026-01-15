# ===============================================
# terminal-enhanced.tests.ps1
# Integration tests for terminal-enhanced.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'terminal-enhanced.ps1 - Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
                . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
        }
        
        It 'Registers Launch-Alacritty function' {
            Get-Command -Name 'Launch-Alacritty' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Kitty function' {
            Get-Command -Name 'Launch-Kitty' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-WezTerm function' {
            Get-Command -Name 'Launch-WezTerm' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Tabby function' {
            Get-Command -Name 'Launch-Tabby' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Start-Tmux function' {
            Get-Command -Name 'Start-Tmux' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-TerminalInfo function' {
            Get-Command -Name 'Get-TerminalInfo' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
        }
        
        It 'Launch-Alacritty handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'alacritty' -Available $false
            
            { Launch-Alacritty -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-Kitty handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'kitty' -Available $false
            
            { Launch-Kitty -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-WezTerm handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'wezterm-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'wezterm' -Available $false
            
            { Launch-WezTerm -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-Tabby handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'tabby' -Available $false
            
            { Launch-Tabby -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Start-Tmux handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'tmux' -Available $false
            
            $result = Start-Tmux -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
        
        It 'Get-TerminalInfo returns empty list when no terminals available' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            # Mock all commands as unavailable
            $allCommands = @('alacritty', 'kitty', 'wezterm-nightly', 'wezterm', 'tabby', 'tmux', 'screen')
            foreach ($cmd in $allCommands) {
                Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
            }
            
            $result = Get-TerminalInfo
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Function Behavior' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
        }
        
        It 'Get-TerminalInfo returns array of terminal objects' {
            $result = Get-TerminalInfo
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Array]
            
            if ($result.Count -gt 0) {
                $result[0] | Should -HaveMember 'Name'
                $result[0] | Should -HaveMember 'Command'
                $result[0] | Should -HaveMember 'Available'
            }
        }
    }
}

