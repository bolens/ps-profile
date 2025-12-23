# ===============================================
# profile-lang-rust-audit.tests.ps1
# Unit tests for Audit-RustProject function
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

Describe 'lang-rust.ps1 - Audit-RustProject' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cargo-audit', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('cargo-audit', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when cargo-audit is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cargo-audit' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'cargo-audit' } -MockWith { return $null }
            
            $result = Audit-RustProject -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls cargo-audit without arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo-audit'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-audit' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'No vulnerabilities found' 
            }
            
            $result = Audit-RustProject
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -BeNullOrEmpty
        }
        
        It 'Calls cargo-audit with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo-audit'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-audit' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Audit complete' 
            }
            
            $result = Audit-RustProject -Arguments @('--deny', 'warnings')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--deny'
            $script:capturedArgs | Should -Contain 'warnings'
        }
    }
    
    Context 'Error handling' {
        It 'Handles cargo-audit execution errors' {
            Setup-AvailableCommandMock -CommandName 'cargo-audit'
            
            Mock -CommandName 'cargo-audit' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('cargo-audit: command failed')
            }
            Mock Write-Error { }
            
            $result = Audit-RustProject -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

