# ===============================================
# profile-ai-tools-lmstudio.tests.ps1
# Unit tests for Invoke-LMStudio function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'ai-tools.ps1')
}

Describe 'ai-tools.ps1 - Invoke-LMStudio' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('lms', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('LMS', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('lms', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('LMS', [ref]$null)
        }
        
        # Reset Test-Path mocks
        Mock Test-Path -MockWith { return $false }
    }
    
    Context 'Tool not available' {
        It 'Returns null when lms is not available' {
            Mock-CommandAvailabilityPester -CommandName 'lms' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'lms' } -MockWith { return $null }
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*\.lmstudio\bin\lms.exe' -or $LiteralPath -like '*\.cache\lm-studio\bin\lms.exe' } -MockWith { return $false }
            
            $result = Invoke-LMStudio -Arguments @('list') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
    }
    
    Context 'Tool available via command' {
        It 'Calls lms with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'lms'
            
            $script:capturedArgs = $null
            Mock -CommandName 'lms' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Models list' 
            }
            
            $result = Invoke-LMStudio -Arguments @('list')
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'lms' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'list'
        }
    }
    
    
    Context 'Error handling' {
        It 'Handles lms execution errors' {
            Setup-AvailableCommandMock -CommandName 'lms'
            
            Mock -CommandName 'lms' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('lms: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-LMStudio -Arguments @('invalid-command') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

