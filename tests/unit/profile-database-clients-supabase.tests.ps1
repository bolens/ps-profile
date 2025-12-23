# ===============================================
# profile-database-clients-supabase.tests.ps1
# Unit tests for Invoke-Supabase function
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

Describe 'database-clients.ps1 - Invoke-Supabase' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('supabase', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('supabase-beta', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('SUPABASE', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('supabase', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('supabase-beta', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('SUPABASE', [ref]$null)
        }
        
        Remove-Item -Path "Function:\supabase" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\supabase-beta" -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Tool not available' {
        It 'Returns null when supabase is not available' {
            Mock-CommandAvailabilityPester -CommandName 'supabase-beta' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'supabase' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'supabase-beta' -or $Name -eq 'supabase' } -MockWith { return $null }
            
            $result = Invoke-Supabase status -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Uses supabase-beta when available' {
            Setup-AvailableCommandMock -CommandName 'supabase-beta'
            Mock-CommandAvailabilityPester -CommandName 'supabase' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'supabase-beta' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Supabase status: running' 
            }
            
            $result = Invoke-Supabase status
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'supabase-beta' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'status'
        }
        
        It 'Falls back to supabase when supabase-beta is not available' {
            Mock-CommandAvailabilityPester -CommandName 'supabase-beta' -Available $false
            Setup-AvailableCommandMock -CommandName 'supabase'
            
            $script:capturedArgs = $null
            Mock -CommandName 'supabase' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Supabase status: running' 
            }
            
            $result = Invoke-Supabase status
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'supabase' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'status'
        }
        
        It 'Calls supabase with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'supabase-beta'
            Mock-CommandAvailabilityPester -CommandName 'supabase' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'supabase-beta' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Local Supabase started' 
            }
            
            $result = Invoke-Supabase start
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'start'
        }
        
        It 'Handles multiple arguments' {
            Setup-AvailableCommandMock -CommandName 'supabase-beta'
            Mock-CommandAvailabilityPester -CommandName 'supabase' -Available $false
            
            $script:capturedArgs = $null
            Mock -CommandName 'supabase-beta' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Migration applied' 
            }
            
            $result = Invoke-Supabase db reset
            
            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'db'
            $script:capturedArgs | Should -Contain 'reset'
        }
        
        It 'Handles command execution errors' {
            Setup-AvailableCommandMock -CommandName 'supabase-beta'
            Mock-CommandAvailabilityPester -CommandName 'supabase' -Available $false
            
            Mock -CommandName 'supabase-beta' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('supabase-beta failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Supabase status -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

