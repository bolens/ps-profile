# ===============================================
# profile-ai-tools-comfyui.tests.ps1
# Unit tests for Invoke-ComfyUI function
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

Describe 'ai-tools.ps1 - Invoke-ComfyUI' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('comfy', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('COMFY', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('comfy', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('COMFY', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when comfy is not available' {
            Mock-CommandAvailabilityPester -CommandName 'comfy' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'comfy' } -MockWith { return $null }
            
            $result = Invoke-ComfyUI -Arguments @('install') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls comfy with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'comfy'
            
            $script:capturedArgs = $null
            Mock -CommandName 'comfy' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'ComfyUI installed' 
            }
            
            $result = Invoke-ComfyUI -Arguments @('install')
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'comfy' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'install'
        }
        
        It 'Handles comfy execution errors' {
            Setup-AvailableCommandMock -CommandName 'comfy'
            
            Mock -CommandName 'comfy' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('comfy: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-ComfyUI -Arguments @('invalid-command') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

