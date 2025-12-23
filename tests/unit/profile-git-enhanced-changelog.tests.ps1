# ===============================================
# profile-git-enhanced-changelog.tests.ps1
# Unit tests for New-GitChangelog function
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

Describe 'git-enhanced.ps1 - New-GitChangelog' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('git-cliff', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('GIT-CLIFF', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('git-cliff', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('GIT-CLIFF', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when git-cliff is not available' {
            Mock-CommandAvailabilityPester -CommandName 'git-cliff' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'git-cliff' } -MockWith { return $null }
            
            $result = New-GitChangelog -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls git-cliff with default output path' {
            Setup-AvailableCommandMock -CommandName 'git-cliff'
            
            $script:capturedArgs = $null
            Mock -CommandName 'git-cliff' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return $null
            }
            
            $result = New-GitChangelog -ErrorAction SilentlyContinue
            
            Should -Invoke -CommandName 'git-cliff' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '--output'
            $script:capturedArgs | Should -Contain 'CHANGELOG.md'
        }
        
        It 'Calls git-cliff with custom output path' {
            Setup-AvailableCommandMock -CommandName 'git-cliff'
            
            $script:capturedArgs = $null
            Mock -CommandName 'git-cliff' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return $null
            }
            
            $result = New-GitChangelog -OutputPath 'docs/CHANGELOG.md' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--output'
            $script:capturedArgs | Should -Contain 'docs/CHANGELOG.md'
        }
        
        It 'Calls git-cliff with config path' {
            Setup-AvailableCommandMock -CommandName 'git-cliff'
            
            $script:capturedArgs = $null
            Mock -CommandName 'git-cliff' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return $null
            }
            
            $result = New-GitChangelog -ConfigPath 'cliff.toml' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--config'
            $script:capturedArgs | Should -Contain 'cliff.toml'
        }
        
        It 'Calls git-cliff with tag' {
            Setup-AvailableCommandMock -CommandName 'git-cliff'
            
            $script:capturedArgs = $null
            Mock -CommandName 'git-cliff' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return $null
            }
            
            $result = New-GitChangelog -Tag 'v1.0.0' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--tag'
            $script:capturedArgs | Should -Contain 'v1.0.0'
        }
        
        It 'Calls git-cliff with latest flag' {
            Setup-AvailableCommandMock -CommandName 'git-cliff'
            
            $script:capturedArgs = $null
            Mock -CommandName 'git-cliff' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return $null
            }
            
            $result = New-GitChangelog -Latest -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--latest'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'git-cliff'
            
            Mock -CommandName 'git-cliff' -MockWith { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = New-GitChangelog -OutputPath 'CHANGELOG.md' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'CHANGELOG.md'
        }
        
        It 'Handles git-cliff execution errors' {
            Setup-AvailableCommandMock -CommandName 'git-cliff'
            
            Mock -CommandName 'git-cliff' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = New-GitChangelog -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

