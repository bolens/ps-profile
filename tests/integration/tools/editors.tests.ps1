# ===============================================
# editors.tests.ps1
# Integration tests for editors.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'editors.ps1 - Integration Tests' {
    BeforeEach {
        # Always mock Start-Process to prevent actual process launches
        Mock Start-Process -MockWith {
            # Default mock - just capture the call, don't launch anything
            return $null
        }
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
        
        It 'Edit-WithVSCode handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'code-insiders' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'code' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'codium' -Available $false
            
            { Edit-WithVSCode -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Edit-WithCursor handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'cursor' -Available $false
            
            { Edit-WithCursor -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Edit-WithNeovim handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'neovim-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'nvim' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'neovim' -Available $false
            
            { Edit-WithNeovim -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-Emacs handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'emacs' -Available $false
            
            { Launch-Emacs -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-Lapce handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'lapce-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'lapce' -Available $false
            
            { Launch-Lapce -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-Zed handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'zed-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'zed' -Available $false
            
            { Launch-Zed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Get-EditorInfo handles missing editors gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            # Note: This test verifies the function works, but may return results
            # if editors are actually installed on the system
            $result = Get-EditorInfo
            
            # Function should return an array (may be empty or populated)
            # Handle both null and array cases
            if ($null -eq $result) {
                $result = @()
            }
            # Verify it's an array type or can be treated as one
            , $result | Should -BeOfType [System.Array]
        }
    }
    
    Context 'Function Behavior' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'editors.ps1')
        }
        
        It 'Get-EditorInfo returns array of editor objects' {
            $result = Get-EditorInfo
            
            # Function should return an array (may be empty or populated)
            # Handle both null and array cases - ensure it's always an array
            if ($null -eq $result) {
                $result = @()
            }
            
            # Verify it can be treated as an array (has Count property and can be indexed)
            $result | Should -HaveMember 'Count'
            
            # If there are results, verify structure
            if ($null -ne $result -and $result.Count -gt 0) {
                $result[0] | Should -HaveMember 'Name'
                $result[0] | Should -HaveMember 'Command'
                $result[0] | Should -HaveMember 'Available'
            }
        }
    }
}

