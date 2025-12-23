# ===============================================
# profile-ai-tools-ollama.tests.ps1
# Unit tests for Invoke-OllamaEnhanced function
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

Describe 'ai-tools.ps1 - Invoke-OllamaEnhanced' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('ollama', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('OLLAMA', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('ollama', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('OLLAMA', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when ollama is not available' {
            Mock-CommandAvailabilityPester -CommandName 'ollama' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'ollama' } -MockWith { return $null }
            
            $result = Invoke-OllamaEnhanced -Arguments @('list') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls ollama with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'ollama'
            
            $script:capturedArgs = $null
            Mock -CommandName 'ollama' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'NAME    ID      SIZE    MODIFIED' 
            }
            
            $result = Invoke-OllamaEnhanced -Arguments @('list')
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'ollama' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'list'
        }
        
        It 'Handles ollama execution errors' {
            Setup-AvailableCommandMock -CommandName 'ollama'
            
            Mock -CommandName 'ollama' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('ollama: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-OllamaEnhanced -Arguments @('invalid-command') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

