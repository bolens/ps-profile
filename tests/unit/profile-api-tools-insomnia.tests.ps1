# ===============================================
# profile-api-tools-insomnia.tests.ps1
# Unit tests for Invoke-Insomnia function
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

Describe 'api-tools.ps1 - Invoke-Insomnia' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('insomnia', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('INSOMNIA', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('insomnia', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('INSOMNIA', [ref]$null)
        }
        
        Remove-Item -Path "Function:\insomnia" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when insomnia is not available' {
            Mock-CommandAvailabilityPester -CommandName 'insomnia' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'insomnia' } -MockWith { return $null }
            
            $result = Invoke-Insomnia -CollectionPath $script:TestCollectionPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls insomnia with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'insomnia'
            
            $script:capturedArgs = $null
            Mock -CommandName 'insomnia' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Insomnia -CollectionPath $script:TestCollectionPath
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'insomnia' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'run'
            $script:capturedArgs | Should -Contain $script:TestCollectionPath
        }
        
        It 'Includes environment parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'insomnia'
            
            $script:capturedArgs = $null
            Mock -CommandName 'insomnia' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Insomnia -CollectionPath $script:TestCollectionPath -Environment 'production'
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--env'
            $script:capturedArgs | Should -Contain 'production'
        }
        
        It 'Uses current directory when CollectionPath is not specified' {
            Setup-AvailableCommandMock -CommandName 'insomnia'
            
            $script:capturedArgs = $null
            Mock -CommandName 'insomnia' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $currentPath = (Get-Location).Path
            $result = Invoke-Insomnia
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $currentPath
        }
        
        It 'Returns error when collection path does not exist' {
            Setup-AvailableCommandMock -CommandName 'insomnia'
            Mock -CommandName 'insomnia' -MockWith { return 'Collection executed' }
            
            $result = Invoke-Insomnia -CollectionPath 'C:\NonExistent\Path' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles pipeline input for CollectionPath' {
            Setup-AvailableCommandMock -CommandName 'insomnia'
            
            $script:capturedArgs = $null
            Mock -CommandName 'insomnia' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = $script:TestCollectionPath | Invoke-Insomnia
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $script:TestCollectionPath
        }
        
        It 'Handles command execution errors' {
            Setup-AvailableCommandMock -CommandName 'insomnia'
            
            Mock -CommandName 'insomnia' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('insomnia failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Insomnia -CollectionPath $script:TestCollectionPath -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

