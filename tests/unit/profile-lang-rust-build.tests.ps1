# ===============================================
# profile-lang-rust-build.tests.ps1
# Unit tests for Build-RustRelease and Update-RustDependencies functions
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

Describe 'lang-rust.ps1 - Build-RustRelease' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cargo', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('cargo', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when cargo is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cargo' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'cargo' } -MockWith { return $null }
            
            $result = Build-RustRelease -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls cargo build --release without arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }
            
            $result = Build-RustRelease
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'build'
            $script:capturedArgs | Should -Contain '--release'
        }
        
        It 'Calls cargo build --release with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }
            
            $result = Build-RustRelease -Arguments @('--bin', 'myapp')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'build'
            $script:capturedArgs | Should -Contain '--release'
            $script:capturedArgs | Should -Contain '--bin'
            $script:capturedArgs | Should -Contain 'myapp'
        }
    }
    
    Context 'Error handling' {
        It 'Handles cargo build execution errors' {
            Setup-AvailableCommandMock -CommandName 'cargo'
            
            Mock -CommandName 'cargo' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('cargo: command failed')
            }
            Mock Write-Error { }
            
            $result = Build-RustRelease -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'lang-rust.ps1 - Update-RustDependencies' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cargo', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('cargo', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when cargo is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cargo' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'cargo' } -MockWith { return $null }
            
            $result = Update-RustDependencies -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls cargo update without arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Dependencies updated' 
            }
            
            $result = Update-RustDependencies
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'update'
        }
        
        It 'Calls cargo update with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'cargo'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cargo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Dependencies updated' 
            }
            
            $result = Update-RustDependencies -Arguments @('--package', 'serde')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'update'
            $script:capturedArgs | Should -Contain '--package'
            $script:capturedArgs | Should -Contain 'serde'
        }
    }
    
    Context 'Error handling' {
        It 'Handles cargo update execution errors' {
            Setup-AvailableCommandMock -CommandName 'cargo'
            
            Mock -CommandName 'cargo' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('cargo: command failed')
            }
            Mock Write-Error { }
            
            $result = Update-RustDependencies -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

