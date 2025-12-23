# ===============================================
# profile-ai-tools-llamacpp.tests.ps1
# Unit tests for Invoke-LlamaCpp function
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

Describe 'ai-tools.ps1 - Invoke-LlamaCpp' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('llama-cpp-cuda', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('llama-cpp', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('llama.cpp', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('llama-cpp-cuda', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('llama-cpp', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('llama.cpp', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when no llama-cpp variant is available' {
            Mock-CommandAvailabilityPester -CommandName 'llama-cpp-cuda' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'llama-cpp' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'llama.cpp' -Available $false
            Mock Get-Command -ParameterFilter { $Name -in @('llama-cpp-cuda', 'llama-cpp', 'llama.cpp') } -MockWith { return $null }
            
            $result = Invoke-LlamaCpp -Arguments @('--help') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available - llama-cpp-cuda' {
        It 'Prefers llama-cpp-cuda when available' {
            Setup-AvailableCommandMock -CommandName 'llama-cpp-cuda'
            Mock-CommandAvailabilityPester -CommandName 'llama-cpp' -Available $false
            
            $script:capturedArgs = $null
            $script:capturedCmd = $null
            Mock -CommandName 'llama-cpp-cuda' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedCmd = 'llama-cpp-cuda'
                $script:capturedArgs = $Arguments
                return 'llama-cpp-cuda help' 
            }
            
            $result = Invoke-LlamaCpp -Arguments @('--help')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedCmd | Should -Be 'llama-cpp-cuda'
            $script:capturedArgs | Should -Contain '--help'
        }
    }
    
    Context 'Tool available - llama-cpp' {
        It 'Falls back to llama-cpp when llama-cpp-cuda is not available' {
            Mock-CommandAvailabilityPester -CommandName 'llama-cpp-cuda' -Available $false
            Setup-AvailableCommandMock -CommandName 'llama-cpp'
            
            $script:capturedArgs = $null
            $script:capturedCmd = $null
            Mock -CommandName 'llama-cpp' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedCmd = 'llama-cpp'
                $script:capturedArgs = $Arguments
                return 'llama-cpp help' 
            }
            
            $result = Invoke-LlamaCpp -Arguments @('--help')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedCmd | Should -Be 'llama-cpp'
            $script:capturedArgs | Should -Contain '--help'
        }
    }
    
    Context 'Tool available - llama.cpp' {
        It 'Falls back to llama.cpp when other variants are not available' {
            Mock-CommandAvailabilityPester -CommandName 'llama-cpp-cuda' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'llama-cpp' -Available $false
            Setup-AvailableCommandMock -CommandName 'llama.cpp'
            
            $script:capturedArgs = $null
            $script:capturedCmd = $null
            Mock -CommandName 'llama.cpp' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedCmd = 'llama.cpp'
                $script:capturedArgs = $Arguments
                return 'llama.cpp help' 
            }
            
            $result = Invoke-LlamaCpp -Arguments @('--help')
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedCmd | Should -Be 'llama.cpp'
            $script:capturedArgs | Should -Contain '--help'
        }
    }
    
    Context 'Error handling' {
        It 'Handles llama-cpp execution errors' {
            Setup-AvailableCommandMock -CommandName 'llama-cpp-cuda'
            
            Mock -CommandName 'llama-cpp-cuda' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('llama-cpp-cuda: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-LlamaCpp -Arguments @('invalid-command') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

