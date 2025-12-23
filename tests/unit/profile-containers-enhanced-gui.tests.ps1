# ===============================================
# profile-containers-enhanced-gui.tests.ps1
# Unit tests for Start-PodmanDesktop and Start-RancherDesktop functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
}

Describe 'containers-enhanced.ps1 - Start-PodmanDesktop' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('podman-desktop', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when podman-desktop is not available' {
            Mock-CommandAvailabilityPester -CommandName 'podman-desktop' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'podman-desktop' } -MockWith { return $null }
            
            $result = Start-PodmanDesktop -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Launches podman-desktop' {
            Setup-AvailableCommandMock -CommandName 'podman-desktop'
            
            $script:capturedFilePath = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
            }
            
            Start-PodmanDesktop -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'podman-desktop'
        }
        
        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'podman-desktop'
            
            Mock Start-Process -MockWith { 
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            Start-PodmanDesktop -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'containers-enhanced.ps1 - Start-RancherDesktop' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('rancher-desktop', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when rancher-desktop is not available' {
            Mock-CommandAvailabilityPester -CommandName 'rancher-desktop' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'rancher-desktop' } -MockWith { return $null }
            
            $result = Start-RancherDesktop -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Launches rancher-desktop' {
            Setup-AvailableCommandMock -CommandName 'rancher-desktop'
            
            $script:capturedFilePath = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
            }
            
            Start-RancherDesktop -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'rancher-desktop'
        }
        
        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'rancher-desktop'
            
            Mock Start-Process -MockWith { 
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            Start-RancherDesktop -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

