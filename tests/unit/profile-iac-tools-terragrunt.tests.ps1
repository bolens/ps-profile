# ===============================================
# profile-iac-tools-terragrunt.tests.ps1
# Unit tests for Invoke-Terragrunt and Invoke-OpenTofu functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'iac-tools.ps1')
}

Describe 'iac-tools.ps1 - Invoke-Terragrunt' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('terragrunt', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when terragrunt is not available' {
            Mock-CommandAvailabilityPester -CommandName 'terragrunt' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'terragrunt' } -MockWith { return $null }
            
            $result = Invoke-Terragrunt plan -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls terragrunt with arguments' {
            Setup-AvailableCommandMock -CommandName 'terragrunt'
            
            $script:capturedArgs = $null
            Mock -CommandName 'terragrunt' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Plan output'
            }
            
            $result = Invoke-Terragrunt plan -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'plan'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls terragrunt with multiple arguments' {
            Setup-AvailableCommandMock -CommandName 'terragrunt'
            
            $script:capturedArgs = $null
            Mock -CommandName 'terragrunt' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Apply output'
            }
            
            $result = Invoke-Terragrunt apply -auto-approve -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'apply'
            $script:capturedArgs | Should -Contain '-auto-approve'
        }
        
        It 'Handles terragrunt execution errors' {
            Setup-AvailableCommandMock -CommandName 'terragrunt'
            
            Mock -CommandName 'terragrunt' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('Command not found')
            }
            Mock Write-Error { }
            
            $result = Invoke-Terragrunt plan -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'iac-tools.ps1 - Invoke-OpenTofu' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('tofu', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when opentofu is not available' {
            Mock-CommandAvailabilityPester -CommandName 'tofu' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'tofu' } -MockWith { return $null }
            
            $result = Invoke-OpenTofu init -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls tofu with arguments' {
            Setup-AvailableCommandMock -CommandName 'tofu'
            
            $script:capturedArgs = $null
            Mock -CommandName 'tofu' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Init output'
            }
            
            $result = Invoke-OpenTofu init -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'init'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls tofu with plan command' {
            Setup-AvailableCommandMock -CommandName 'tofu'
            
            $script:capturedArgs = $null
            Mock -CommandName 'tofu' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Plan output'
            }
            
            $result = Invoke-OpenTofu plan -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'plan'
        }
        
        It 'Handles opentofu execution errors' {
            Setup-AvailableCommandMock -CommandName 'tofu'
            
            Mock -CommandName 'tofu' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('Command not found')
            }
            Mock Write-Error { }
            
            $result = Invoke-OpenTofu plan -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

