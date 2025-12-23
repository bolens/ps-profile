# ===============================================
# profile-api-tools-bruno.tests.ps1
# Unit tests for Invoke-Bruno function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')
    
    # Create test directories
    if (Get-Variable -Name TestDrive -ErrorAction SilentlyContinue) {
        $script:TestCollectionPath = Join-Path $TestDrive 'TestCollection'
        New-Item -ItemType Directory -Path $script:TestCollectionPath -Force | Out-Null
    }
}

Describe 'api-tools.ps1 - Invoke-Bruno' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('bruno', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('BRUNO', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('bruno', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('BRUNO', [ref]$null)
        }
        
        Remove-Item -Path "Function:\bruno" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when bruno is not available' {
            Mock-CommandAvailabilityPester -CommandName 'bruno' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'bruno' } -MockWith { return $null }
            
            $result = Invoke-Bruno -CollectionPath $script:TestCollectionPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls bruno with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'bruno'
            
            $script:capturedArgs = $null
            Mock -CommandName 'bruno' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Bruno -CollectionPath $script:TestCollectionPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'bruno' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'run'
            $script:capturedArgs | Should -Contain $script:TestCollectionPath
        }
        
        It 'Includes environment parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'bruno'
            
            $script:capturedArgs = $null
            Mock -CommandName 'bruno' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Bruno -CollectionPath $script:TestCollectionPath -Environment 'production'
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--env'
            $script:capturedArgs | Should -Contain 'production'
        }
        
        It 'Uses current directory when CollectionPath is not specified' {
            Setup-AvailableCommandMock -CommandName 'bruno'
            
            $script:capturedArgs = $null
            Mock -CommandName 'bruno' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $currentPath = (Get-Location).Path
            $result = Invoke-Bruno
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $currentPath
        }
        
        It 'Returns error when collection path does not exist' {
            Setup-AvailableCommandMock -CommandName 'bruno'
            Mock -CommandName 'bruno' -MockWith { return 'Collection executed' }
            
            $result = Invoke-Bruno -CollectionPath 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles pipeline input for CollectionPath' {
            Setup-AvailableCommandMock -CommandName 'bruno'
            
            $script:capturedArgs = $null
            Mock -CommandName 'bruno' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = $script:TestCollectionPath | Invoke-Bruno
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $script:TestCollectionPath
        }
        
        It 'Handles command execution errors' {
            Setup-AvailableCommandMock -CommandName 'bruno'
            
            Mock -CommandName 'bruno' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('bruno failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Bruno -CollectionPath $script:TestCollectionPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

