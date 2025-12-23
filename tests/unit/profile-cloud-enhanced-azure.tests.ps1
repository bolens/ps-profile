# ===============================================
# profile-cloud-enhanced-azure.tests.ps1
# Unit tests for Set-AzureSubscription function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
}

Describe 'cloud-enhanced.ps1 - Set-AzureSubscription' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('az', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when az is not available' {
            Mock-CommandAvailabilityPester -CommandName 'az' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'az' } -MockWith { return $null }
            
            $result = Set-AzureSubscription -List -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Lists subscriptions when List is specified' {
            Setup-AvailableCommandMock -CommandName 'az'
            
            $script:capturedArgs = $null
            Mock -CommandName 'az' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Subscription list'
            }
            
            $result = Set-AzureSubscription -List -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'account'
            $script:capturedArgs | Should -Contain 'list'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Switches subscription when SubscriptionId is specified' {
            Setup-AvailableCommandMock -CommandName 'az'
            
            $script:capturedArgs = $null
            Mock -CommandName 'az' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-Host { }
            
            $result = Set-AzureSubscription -SubscriptionId 'sub-123' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'account'
            $script:capturedArgs | Should -Contain 'set'
            $script:capturedArgs | Should -Contain '--subscription'
            $script:capturedArgs | Should -Contain 'sub-123'
        }
        
        It 'Shows current subscription when no parameters' {
            Setup-AvailableCommandMock -CommandName 'az'
            
            $script:capturedArgs = $null
            Mock -CommandName 'az' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Current subscription'
            }
            
            $result = Set-AzureSubscription -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'account'
            $script:capturedArgs | Should -Contain 'show'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles az execution errors' {
            Setup-AvailableCommandMock -CommandName 'az'
            
            Mock -CommandName 'az' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Set-AzureSubscription -List -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

