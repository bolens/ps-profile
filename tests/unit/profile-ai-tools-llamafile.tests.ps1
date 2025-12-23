# ===============================================
# profile-ai-tools-llamafile.tests.ps1
# Unit tests for Invoke-Llamafile function
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

Describe 'ai-tools.ps1 - Invoke-Llamafile' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('llamafile', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('LLAMAFILE', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('llamafile', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('LLAMAFILE', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when llamafile is not available' {
            Mock-CommandAvailabilityPester -CommandName 'llamafile' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'llamafile' } -MockWith { return $null }
            
            $result = Invoke-Llamafile -Arguments @('--help') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls llamafile with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'llamafile'
            
            $script:capturedArgs = $null
            Mock -CommandName 'llamafile' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Llamafile help' 
            }
            
            $result = Invoke-Llamafile -Arguments @('--help')
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'llamafile' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '--help'
        }
        
        It 'Includes Model parameter in arguments' {
            Setup-AvailableCommandMock -CommandName 'llamafile'
            
            $script:capturedArgs = $null
            Mock -CommandName 'llamafile' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Model output' 
            }
            
            $modelPath = 'test-model.llamafile'
            $result = Invoke-Llamafile -Model $modelPath
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $modelPath
        }
        
        It 'Includes Prompt parameter in arguments' {
            Setup-AvailableCommandMock -CommandName 'llamafile'
            
            $script:capturedArgs = $null
            Mock -CommandName 'llamafile' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Prompt response' 
            }
            
            $prompt = 'Hello, world!'
            $result = Invoke-Llamafile -Prompt $prompt
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--prompt'
            $script:capturedArgs | Should -Contain $prompt
        }
        
        It 'Combines Model, Prompt, and Arguments' {
            Setup-AvailableCommandMock -CommandName 'llamafile'
            
            $script:capturedArgs = $null
            Mock -CommandName 'llamafile' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Combined output' 
            }
            
            $result = Invoke-Llamafile -Model 'model.llamafile' -Prompt 'Test prompt' -Arguments @('--ctx-size', '2048')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'model.llamafile'
            $script:capturedArgs | Should -Contain '--prompt'
            $script:capturedArgs | Should -Contain 'Test prompt'
            $script:capturedArgs | Should -Contain '--ctx-size'
            $script:capturedArgs | Should -Contain '2048'
        }
        
        It 'Handles llamafile execution errors' {
            Setup-AvailableCommandMock -CommandName 'llamafile'
            
            Mock -CommandName 'llamafile' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('llamafile: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Llamafile -Arguments @('invalid-command') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

