# ===============================================
# profile-api-tools-httpie.tests.ps1
# Unit tests for Invoke-Httpie function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')
}

Describe 'api-tools.ps1 - Invoke-Httpie' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('http', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('HTTP', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('http', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('HTTP', [ref]$null)
        }
        
        Remove-Item -Path "Function:\http" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when httpie is not available' {
            Mock-CommandAvailabilityPester -CommandName 'http' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'http' } -MockWith { return $null }
            
            $result = Invoke-Httpie -Url 'https://api.example.com/test' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls http with GET method by default' {
            Setup-AvailableCommandMock -CommandName 'http'
            
            $script:capturedArgs = $null
            Mock -CommandName 'http' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Response' 
            }
            
            $testUrl = 'https://api.example.com/test'
            $result = Invoke-Httpie -Url $testUrl
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'http' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain $testUrl
            $script:capturedArgs | Should -Not -Contain 'GET'
        }
        
        It 'Calls http with specified method' {
            Setup-AvailableCommandMock -CommandName 'http'
            
            $script:capturedArgs = $null
            Mock -CommandName 'http' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Response' 
            }
            
            $testUrl = 'https://api.example.com/test'
            $result = Invoke-Httpie -Method POST -Url $testUrl
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'POST'
            $script:capturedArgs | Should -Contain $testUrl
        }
        
        It 'Includes body parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'http'
            
            $script:capturedArgs = $null
            Mock -CommandName 'http' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Response' 
            }
            
            $testUrl = 'https://api.example.com/test'
            $testBody = '{"name":"test"}'
            $result = Invoke-Httpie -Method POST -Url $testUrl -Body $testBody
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $testBody
        }
        
        It 'Includes header parameters when specified' {
            Setup-AvailableCommandMock -CommandName 'http'
            
            $script:capturedArgs = $null
            Mock -CommandName 'http' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Response' 
            }
            
            $testUrl = 'https://api.example.com/test'
            $result = Invoke-Httpie -Url $testUrl -Header 'Authorization: Bearer token', 'Content-Type: application/json'
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'Authorization: Bearer token'
            $script:capturedArgs | Should -Contain 'Content-Type: application/json'
        }
        
        It 'Includes output parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'http'
            
            $script:capturedArgs = $null
            $outputFile = Join-Path $TestDrive 'output.json'
            Mock -CommandName 'http' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Response' 
            }
            
            $testUrl = 'https://api.example.com/test'
            $result = Invoke-Httpie -Url $testUrl -Output $outputFile
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--output'
            $script:capturedArgs | Should -Contain $outputFile
        }
        
        It 'Returns error when URL is null or whitespace' {
            Setup-AvailableCommandMock -CommandName 'http'
            Mock -CommandName 'http' -MockWith { return 'Response' }
            Mock Write-Error { }
            
            # Test with whitespace (empty string after trimming)
            # Since Url is Mandatory, we need to pass something, but the function checks for IsNullOrWhiteSpace
            # We'll test the internal check by using a whitespace-only string
            $result = Invoke-Httpie -Url '   ' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
        
        It 'Handles pipeline input for Url' {
            Setup-AvailableCommandMock -CommandName 'http'
            
            $script:capturedArgs = $null
            $testUrl = 'https://api.example.com/test'
            Mock -CommandName 'http' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Response' 
            }
            
            $result = $testUrl | Invoke-Httpie
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain $testUrl
        }
        
        It 'Handles command execution errors' {
            Setup-AvailableCommandMock -CommandName 'http'
            
            Mock -CommandName 'http' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('http failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Httpie -Url 'https://api.example.com/test' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

