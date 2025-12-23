# ===============================================
# profile-lang-rust-outdated.tests.ps1
# Unit tests for Test-RustOutdated function
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

Describe 'lang-rust.ps1 - Test-RustOutdated' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cargo-outdated', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('cargo-outdated', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when cargo-outdated is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cargo-outdated' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'cargo-outdated' } -MockWith { return $null }
            
            $result = Test-RustOutdated -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls cargo-outdated without arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo-outdated'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-outdated' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'All dependencies are up to date' 
            }
            
            $result = Test-RustOutdated
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -BeNullOrEmpty
        }
        
        It 'Calls cargo-outdated with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo-outdated'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-outdated' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Outdated dependencies found' 
            }
            
            $result = Test-RustOutdated -Arguments @('--aggressive')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--aggressive'
        }
    }
    
    Context 'Error handling' {
        It 'Handles cargo-outdated execution errors' {
            Setup-AvailableCommandMock -CommandName 'cargo-outdated'
            
            Mock -CommandName 'cargo-outdated' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('cargo-outdated: command failed')
            }
            Mock Write-Error { }
            
            $result = Test-RustOutdated -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

