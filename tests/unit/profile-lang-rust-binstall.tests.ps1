# ===============================================
# profile-lang-rust-binstall.tests.ps1
# Unit tests for Install-RustBinary function
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

Describe 'lang-rust.ps1 - Install-RustBinary' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cargo-binstall', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('cargo-binstall', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when cargo-binstall is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cargo-binstall' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'cargo-binstall' } -MockWith { return $null }
            
            $result = Install-RustBinary -Packages @('cargo-watch') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls cargo-binstall with package names' {
            Setup-AvailableCommandMock -CommandName 'cargo-binstall'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-binstall' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed cargo-watch' 
            }
            
            $result = Install-RustBinary -Packages @('cargo-watch')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'cargo-watch'
        }
        
        It 'Calls cargo-binstall with version flag when specified' {
            Setup-AvailableCommandMock -CommandName 'cargo-binstall'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-binstall' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed cargo-audit' 
            }
            
            $result = Install-RustBinary -Packages @('cargo-audit') -Version '0.18.0'
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--version'
            $script:capturedArgs | Should -Contain '0.18.0'
            $script:capturedArgs | Should -Contain 'cargo-audit'
        }
        
        It 'Calls cargo-binstall with multiple packages' {
            Setup-AvailableCommandMock -CommandName 'cargo-binstall'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-binstall' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed packages' 
            }
            
            $result = Install-RustBinary -Packages @('cargo-watch', 'cargo-audit')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'cargo-watch'
            $script:capturedArgs | Should -Contain 'cargo-audit'
        }
    }
    
    Context 'Error handling' {
        It 'Handles cargo-binstall execution errors' {
            Setup-AvailableCommandMock -CommandName 'cargo-binstall'
            
            Mock -CommandName 'cargo-binstall' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('cargo-binstall: command failed')
            }
            Mock Write-Error { }
            
            $result = Install-RustBinary -Packages @('invalid-package') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

