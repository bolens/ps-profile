# ===============================================
# profile-database-clients-hasura.tests.ps1
# Unit tests for Invoke-Hasura function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database-clients.ps1')
}

Describe 'database-clients.ps1 - Invoke-Hasura' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('hasura-cli', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('HASURA-CLI', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('hasura-cli', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('HASURA-CLI', [ref]$null)
        }
        
        Remove-Item -Path "Function:\hasura" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\hasura-cli" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when hasura-cli is not available' {
            Mock-CommandAvailabilityPester -CommandName 'hasura-cli' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'hasura-cli' } -MockWith { return $null }
            
            $result = Invoke-Hasura version -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls hasura-cli with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'hasura-cli'
            
            $script:capturedArgs = $null
            Mock -CommandName 'hasura-cli' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Hasura CLI version 2.0.0' 
            }
            
            $result = Invoke-Hasura version
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'hasura-cli' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'version'
        }
        
        It 'Handles multiple arguments' {
            Setup-AvailableCommandMock -CommandName 'hasura-cli'
            
            $script:capturedArgs = $null
            Mock -CommandName 'hasura-cli' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Migration applied' 
            }
            
            $result = Invoke-Hasura migrate apply
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'migrate'
            $script:capturedArgs | Should -Contain 'apply'
        }
        
        It 'Handles command execution errors' {
            Setup-AvailableCommandMock -CommandName 'hasura-cli'
            
            Mock -CommandName 'hasura-cli' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('hasura-cli failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Hasura version -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

