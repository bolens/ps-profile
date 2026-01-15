# ===============================================
# profile-mobile-dev-ios.tests.ps1
# Unit tests for iOS functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
}

Describe 'mobile-dev.ps1 - iOS Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('idevice_id', [ref]$null)
        }
    }
    
    Context 'Connect-IOSDevice' {
        It 'Returns empty array when idevice_id is not available' {
            Mock-CommandAvailabilityPester -CommandName 'idevice_id' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'idevice_id' } -MockWith { return $null }
            
            $result = Connect-IOSDevice -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Lists devices when ListDevices is specified' {
            Setup-AvailableCommandMock -CommandName 'idevice_id'
            Mock -CommandName 'idevice_id' -MockWith {
                $global:LASTEXITCODE = 0
                return @('a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0', 'f0e9d8c7b6a5f4e3d2c1b0a9f8e7d6c5b4a3')
            }
            
            $result = Connect-IOSDevice -ListDevices -ErrorAction SilentlyContinue
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }
        
        It 'Verifies specific device ID when provided' {
            Setup-AvailableCommandMock -CommandName 'idevice_id'
            Mock -CommandName 'idevice_id' -MockWith {
                $global:LASTEXITCODE = 0
                return @('a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0', 'f0e9d8c7b6a5f4e3d2c1b0a9f8e7d6c5b4a3')
            }
            
            $result = Connect-IOSDevice -DeviceId 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0' -ErrorAction SilentlyContinue
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0'
        }
        
        It 'Warns when device ID not found' {
            Setup-AvailableCommandMock -CommandName 'idevice_id'
            Mock -CommandName 'idevice_id' -MockWith {
                $global:LASTEXITCODE = 0
                return @('a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0')
            }
            
            $result = Connect-IOSDevice -DeviceId 'nonexistent-device-id' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
}

