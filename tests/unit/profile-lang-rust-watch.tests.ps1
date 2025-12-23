# ===============================================
# profile-lang-rust-watch.tests.ps1
# Unit tests for Watch-RustProject function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-rust.ps1')
}

Describe 'lang-rust.ps1 - Watch-RustProject' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cargo-watch', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('cargo-watch', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when cargo-watch is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cargo-watch' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'cargo-watch' } -MockWith { return $null }
            
            $result = Watch-RustProject -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls cargo-watch with default check command' {
            Setup-AvailableCommandMock -CommandName 'cargo-watch'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-watch' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Watching for changes...' 
            }
            
            $result = Watch-RustProject
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '-x'
            $script:capturedArgs | Should -Contain 'cargo check'
        }
        
        It 'Calls cargo-watch with specified command' {
            Setup-AvailableCommandMock -CommandName 'cargo-watch'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-watch' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Watching for changes...' 
            }
            
            $result = Watch-RustProject -Command 'test'
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '-x'
            $script:capturedArgs | Should -Contain 'cargo test'
        }
        
        It 'Calls cargo-watch with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo-watch'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-watch' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Watching for changes...' 
            }
            
            $result = Watch-RustProject -Command 'run' -Arguments @('--release')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--'
            $script:capturedArgs | Should -Contain '--release'
        }
    }
    
    Context 'Error handling' {
        It 'Handles cargo-watch execution errors' {
            Setup-AvailableCommandMock -CommandName 'cargo-watch'
            
            Mock -CommandName 'cargo-watch' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('cargo-watch: command failed')
            }
            Mock Write-Error { }
            
            $result = Watch-RustProject -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

