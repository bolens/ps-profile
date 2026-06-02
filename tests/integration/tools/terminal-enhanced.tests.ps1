# ===============================================
# terminal-enhanced.tests.ps1
# Integration tests for terminal-enhanced.ps1 module
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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
        BeforeEach {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
        }

        BeforeAll {
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
        }

        It 'Launch-Alacritty handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'alacritty' -Available $false

            $output = & { Launch-Alacritty -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'alacritty not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'alacritty'
        }

        It 'Launch-Kitty handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'kitty' -Available $false

            $output = & { Launch-Kitty -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'kitty not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kitty'
        }

        It 'Launch-WezTerm handles missing tools gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'wezterm-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'wezterm' -Available $false

            $output = & { Launch-WezTerm -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'wezterm-nightly not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'wezterm-nightly'
        }

        It 'Launch-Tabby handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'tabby' -Available $false

            $output = & { Launch-Tabby -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'tabby not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'tabby'
        }

        It 'Start-Tmux handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'tmux' -Available $false

            $output = & { Start-Tmux -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'tmux not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'tmux'
        }

        It 'Get-TerminalInfo returns empty list when no terminals available' {
            foreach ($cmd in @('alacritty', 'kitty', 'wezterm-nightly', 'wezterm', 'tabby', 'tmux', 'screen')) {
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
            $result = @(Get-TerminalInfo)

            $result | Should -BeOfType [System.Array]
            if ($result.Count -eq 0) {
                Set-ItResult -Inconclusive -Because 'No terminal emulators detected on PATH in this environment'
                return
            }

            $first = $result | Select-Object -First 1
            $first.Name | Should -Not -BeNullOrEmpty
            $first.Command | Should -Not -BeNullOrEmpty
            $first.Available | Should -BeTrue
        }
    }
}

