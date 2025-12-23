# ===============================================
# profile-ai-tools-koboldcpp.tests.ps1
# Unit tests for Invoke-KoboldCpp function
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

Describe 'ai-tools.ps1 - Invoke-KoboldCpp' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('koboldcpp', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('KOBOLDCPP', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('koboldcpp', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('KOBOLDCPP', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when koboldcpp is not available' {
            Mock-CommandAvailabilityPester -CommandName 'koboldcpp' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'koboldcpp' } -MockWith { return $null }
            
            $result = Invoke-KoboldCpp -Arguments @('--help') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls koboldcpp with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'koboldcpp'
            
            $script:capturedArgs = $null
            Mock -CommandName 'koboldcpp' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'KoboldCpp help' 
            }
            
            $result = Invoke-KoboldCpp -Arguments @('--help')
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'koboldcpp' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '--help'
        }
        
        It 'Handles koboldcpp execution errors' {
            Setup-AvailableCommandMock -CommandName 'koboldcpp'
            
            Mock -CommandName 'koboldcpp' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('koboldcpp: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-KoboldCpp -Arguments @('invalid-command') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

