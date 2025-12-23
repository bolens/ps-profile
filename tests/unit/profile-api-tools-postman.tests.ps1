# ===============================================
# profile-api-tools-postman.tests.ps1
# Unit tests for Invoke-Postman function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')
    
    # Create test files
    if (Get-Variable -Name TestDrive -ErrorAction SilentlyContinue) {
        $script:TestCollectionFile = Join-Path $TestDrive 'collection.json'
        $script:TestEnvironmentFile = Join-Path $TestDrive 'environment.json'
        Set-Content -Path $script:TestCollectionFile -Value '{"info":{"name":"Test Collection"}}'
        Set-Content -Path $script:TestEnvironmentFile -Value '{"name":"test"}'
    }
}

Describe 'api-tools.ps1 - Invoke-Postman' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('newman', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('NEWMAN', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('newman', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('NEWMAN', [ref]$null)
        }
        
        Remove-Item -Path "Function:\newman" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\postman" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when newman is not available' {
            Mock-CommandAvailabilityPester -CommandName 'newman' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'newman' } -MockWith { return $null }
            
            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls newman with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'newman'
            
            $script:capturedArgs = $null
            Mock -CommandName 'newman' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'newman' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'run'
            $script:capturedArgs | Should -Contain $script:TestCollectionFile
        }
        
        It 'Includes environment parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'newman'
            
            $script:capturedArgs = $null
            Mock -CommandName 'newman' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -Environment $script:TestEnvironmentFile
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--environment'
            $script:capturedArgs | Should -Contain $script:TestEnvironmentFile
        }
        
        It 'Includes reporters when specified' {
            Setup-AvailableCommandMock -CommandName 'newman'
            
            $script:capturedArgs = $null
            Mock -CommandName 'newman' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -Reporters 'html', 'json'
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--reporter'
            $script:capturedArgs | Should -Contain 'html'
            $script:capturedArgs | Should -Contain '--reporter'
            $script:capturedArgs | Should -Contain 'json'
        }
        
        It 'Includes output file when specified with single reporter' {
            Setup-AvailableCommandMock -CommandName 'newman'
            
            $script:capturedArgs = $null
            $outputFile = Join-Path $TestDrive 'report.html'
            Mock -CommandName 'newman' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -Reporters 'html' -OutputFile $outputFile
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $outputFile
        }
        
        It 'Accepts URL for collection path' {
            Setup-AvailableCommandMock -CommandName 'newman'
            
            $script:capturedArgs = $null
            $collectionUrl = 'https://api.postman.com/collections/12345'
            Mock -CommandName 'newman' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = Invoke-Postman -CollectionPath $collectionUrl
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $collectionUrl
        }
        
        It 'Returns error when collection path does not exist and is not a URL' {
            Setup-AvailableCommandMock -CommandName 'newman'
            Mock -CommandName 'newman' -MockWith { return 'Collection executed' }
            
            $result = Invoke-Postman -CollectionPath 'C:\NonExistent\collection.json' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns error when environment file does not exist' {
            Setup-AvailableCommandMock -CommandName 'newman'
            Mock -CommandName 'newman' -MockWith { return 'Collection executed' }
            
            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -Environment 'C:\NonExistent\env.json' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles pipeline input for CollectionPath' {
            Setup-AvailableCommandMock -CommandName 'newman'
            
            $script:capturedArgs = $null
            Mock -CommandName 'newman' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Collection executed' 
            }
            
            $result = $script:TestCollectionFile | Invoke-Postman
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $script:TestCollectionFile
        }
        
        It 'Handles command execution errors' {
            Setup-AvailableCommandMock -CommandName 'newman'
            
            Mock -CommandName 'newman' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('newman failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

