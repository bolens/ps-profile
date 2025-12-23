# ===============================================
# profile-api-tools-hurl.tests.ps1
# Unit tests for Invoke-Hurl function
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
        $script:TestHurlFile = Join-Path $TestDrive 'test.hurl'
        Set-Content -Path $script:TestHurlFile -Value 'GET https://api.example.com/test'
    }
}

Describe 'api-tools.ps1 - Invoke-Hurl' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('hurl', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('HURL', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('hurl', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('HURL', [ref]$null)
        }
        
        Remove-Item -Path "Function:\hurl" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when hurl is not available' {
            Mock-CommandAvailabilityPester -CommandName 'hurl' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'hurl' } -MockWith { return $null }
            
            $result = Invoke-Hurl -TestFile $script:TestHurlFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls hurl with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'hurl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'hurl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Test executed' 
            }
            
            $result = Invoke-Hurl -TestFile $script:TestHurlFile
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'hurl' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain $script:TestHurlFile
        }
        
        It 'Includes variable parameters when specified' {
            Setup-AvailableCommandMock -CommandName 'hurl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'hurl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Test executed' 
            }
            
            $result = Invoke-Hurl -TestFile $script:TestHurlFile -Variable 'base_url=https://api.example.com', 'token=abc123'
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--variable'
            $script:capturedArgs | Should -Contain 'base_url=https://api.example.com'
            $script:capturedArgs | Should -Contain '--variable'
            $script:capturedArgs | Should -Contain 'token=abc123'
        }
        
        It 'Includes output parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'hurl'
            
            $script:capturedArgs = $null
            $outputFile = Join-Path $TestDrive 'output.json'
            Mock -CommandName 'hurl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Test executed' 
            }
            
            $result = Invoke-Hurl -TestFile $script:TestHurlFile -Output $outputFile
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--output'
            $script:capturedArgs | Should -Contain $outputFile
        }
        
        It 'Returns error when test file does not exist' {
            Setup-AvailableCommandMock -CommandName 'hurl'
            Mock -CommandName 'hurl' -MockWith { return 'Test executed' }
            
            $result = Invoke-Hurl -TestFile 'C:\NonExistent\test.hurl' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Handles pipeline input for TestFile' {
            Setup-AvailableCommandMock -CommandName 'hurl'
            
            $script:capturedArgs = $null
            Mock -CommandName 'hurl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Test executed' 
            }
            
            $result = $script:TestHurlFile | Invoke-Hurl
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $script:TestHurlFile
        }
        
        It 'Handles command execution errors' {
            Setup-AvailableCommandMock -CommandName 'hurl'
            
            Mock -CommandName 'hurl' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('hurl failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Hurl -TestFile $script:TestHurlFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

