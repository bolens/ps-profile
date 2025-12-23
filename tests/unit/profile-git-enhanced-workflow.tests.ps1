# ===============================================
# profile-git-enhanced-workflow.tests.ps1
# Unit tests for Invoke-GitButler and Invoke-Jujutsu functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
}

Describe 'git-enhanced.ps1 - Invoke-GitButler' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('gitbutler', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('GITBUTLER', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('gitbutler', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('GITBUTLER', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when gitbutler is not available' {
            Mock-CommandAvailabilityPester -CommandName 'gitbutler' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'gitbutler' } -MockWith { return $null }
            
            $result = Invoke-GitButler -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls gitbutler without arguments' {
            Setup-AvailableCommandMock -CommandName 'gitbutler'
            
            $script:capturedArgs = $null
            Mock -CommandName 'gitbutler' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Git Butler output'
            }
            
            $result = Invoke-GitButler -ErrorAction SilentlyContinue
            
            Should -Invoke -CommandName 'gitbutler' -Times 1 -Exactly
            $script:capturedArgs | Should -BeNullOrEmpty
        }
        
        It 'Calls gitbutler with arguments' {
            Setup-AvailableCommandMock -CommandName 'gitbutler'
            
            $script:capturedArgs = $null
            Mock -CommandName 'gitbutler' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Git Butler output'
            }
            
            $result = Invoke-GitButler -Arguments @('status', 'sync') -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'status'
            $script:capturedArgs | Should -Contain 'sync'
        }
        
        It 'Handles gitbutler execution errors' {
            Setup-AvailableCommandMock -CommandName 'gitbutler'
            
            Mock -CommandName 'gitbutler' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('gitbutler: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-GitButler -Arguments @('invalid') -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'git-enhanced.ps1 - Invoke-Jujutsu' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('jj', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('JJ', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('jj', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('JJ', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when jj is not available' {
            Mock-CommandAvailabilityPester -CommandName 'jj' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'jj' } -MockWith { return $null }
            
            $result = Invoke-Jujutsu -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls jj without arguments' {
            Setup-AvailableCommandMock -CommandName 'jj'
            
            $script:capturedArgs = $null
            Mock -CommandName 'jj' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Jujutsu output'
            }
            
            $result = Invoke-Jujutsu -ErrorAction SilentlyContinue
            
            Should -Invoke -CommandName 'jj' -Times 1 -Exactly
            $script:capturedArgs | Should -BeNullOrEmpty
        }
        
        It 'Calls jj with arguments' {
            Setup-AvailableCommandMock -CommandName 'jj'
            
            $script:capturedArgs = $null
            Mock -CommandName 'jj' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Jujutsu output'
            }
            
            $result = Invoke-Jujutsu -Arguments @('init', 'status') -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'init'
            $script:capturedArgs | Should -Contain 'status'
        }
        
        It 'Handles jj execution errors' {
            Setup-AvailableCommandMock -CommandName 'jj'
            
            Mock -CommandName 'jj' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('jj: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Jujutsu -Arguments @('invalid') -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

