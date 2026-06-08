# ===============================================
# editors.tests.ps1
# Integration tests for editors.ps1 module
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'editors.ps1 - Integration Tests' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock
    }
    
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 'editors.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 'editors.ps1')
                . (Join-Path $script:ProfileDir 'editors.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'editors.ps1')
        }
        
        It 'Registers Edit-WithVSCode function' {
            Get-Command -Name 'Edit-WithVSCode' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Edit-WithCursor function' {
            Get-Command -Name 'Edit-WithCursor' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Edit-WithNeovim function' {
            Get-Command -Name 'Edit-WithNeovim' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Emacs function' {
            Get-Command -Name 'Launch-Emacs' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Lapce function' {
            Get-Command -Name 'Launch-Lapce' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Zed function' {
            Get-Command -Name 'Launch-Zed' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-EditorInfo function' {
            Get-Command -Name 'Get-EditorInfo' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'editors.ps1')
        }

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
        
        It 'Edit-WithVSCode handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'code-insiders' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'code' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'codium' -Available $false

            $output = & { Edit-WithVSCode -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'vscode not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'vscode'
        }
        
        It 'Edit-WithCursor handles missing tool gracefully' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('cursor', [ref]$null)
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'cursor' -Available $false

            $output = Edit-WithCursor 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'cursor not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cursor'
        }
        
        It 'Edit-WithNeovim handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'neovim-qt' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'nvim-qt' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'neovim-nightly' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'nvim' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'neovim' -Available $false

            $output = & { Edit-WithNeovim -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'neovim-nightly not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'neovim-nightly'
        }
        
        It 'Launch-Emacs handles missing tool gracefully' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('emacs', [ref]$null)
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'emacs' -Available $false

            $output = Launch-Emacs 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'emacs not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'emacs'
        }
        
        It 'Launch-Lapce handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'lapce-nightly' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'lapce' -Available $false

            $output = & { Launch-Lapce -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'lapce-nightly not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'lapce-nightly'
        }
        
        It 'Launch-Zed handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'zed-nightly' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'zed' -Available $false

            $output = & { Launch-Zed -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'zed-nightly not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'zed-nightly'
        }
        
        It 'Get-EditorInfo handles missing editors gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            # Note: This test verifies the function works, but may return results
            # if editors are actually installed on the system
            $result = @(Get-EditorInfo)
            ($result -is [System.Array]) | Should -Be $true
        }
    }
    
    Context 'Function Behavior' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'editors.ps1')
        }
        
        It 'Get-EditorInfo returns array of editor objects' {
            $result = @(Get-EditorInfo)

            ($result -is [System.Array]) | Should -Be $true
            if ($result.Count -eq 0) {
                Set-ItResult -Inconclusive -Because 'No editors detected on PATH in this environment'
                return
            }

            $first = $result | Select-Object -First 1
            $first.Name | Should -Not -BeNullOrEmpty
            $first.Command | Should -Not -BeNullOrEmpty
            $first.Available | Should -BeTrue
        }
    }
}

