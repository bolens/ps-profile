# ===============================================
# profile-git-enhanced-gui.tests.ps1
# Unit tests for Invoke-GitTower and Invoke-GitKraken functions
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

Describe 'git-enhanced.ps1 - Invoke-GitTower' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('git-tower', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('GIT-TOWER', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('git-tower', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('GIT-TOWER', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when git-tower is not available' {
            Mock-CommandAvailabilityPester -CommandName 'git-tower' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'git-tower' } -MockWith { return $null }
            
            $result = Invoke-GitTower -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Launches git-tower with default path' {
            Setup-AvailableCommandMock -CommandName 'git-tower'
            
            $script:capturedFilePath = $null
            $script:capturedArgs = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
                $script:capturedArgs = $ArgumentList
            }
            
            Invoke-GitTower -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'git-tower'
            $script:capturedArgs | Should -Not -BeNullOrEmpty
        }
        
        It 'Launches git-tower with custom repository path' {
            Setup-AvailableCommandMock -CommandName 'git-tower'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedArgs = $ArgumentList
            }
            
            Invoke-GitTower -RepositoryPath 'C:\Projects\MyRepo' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'C:\Projects\MyRepo'
        }
        
        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'git-tower'
            
            Mock Start-Process -MockWith { 
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            Invoke-GitTower -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'git-enhanced.ps1 - Invoke-GitKraken' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('gitkraken', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('GITKRAKEN', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('gitkraken', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('GITKRAKEN', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when gitkraken is not available' {
            Mock-CommandAvailabilityPester -CommandName 'gitkraken' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'gitkraken' } -MockWith { return $null }
            
            $result = Invoke-GitKraken -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Launches gitkraken with default path' {
            Setup-AvailableCommandMock -CommandName 'gitkraken'
            
            $script:capturedFilePath = $null
            $script:capturedArgs = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
                $script:capturedArgs = $ArgumentList
            }
            
            Invoke-GitKraken -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'gitkraken'
            $script:capturedArgs | Should -Not -BeNullOrEmpty
        }
        
        It 'Launches gitkraken with custom repository path' {
            Setup-AvailableCommandMock -CommandName 'gitkraken'
            
            $script:capturedArgs = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedArgs = $ArgumentList
            }
            
            Invoke-GitKraken -RepositoryPath 'C:\Projects\MyRepo' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'C:\Projects\MyRepo'
        }
        
        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'gitkraken'
            
            Mock Start-Process -MockWith { 
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            Invoke-GitKraken -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

