# ===============================================
# profile-game-emulators-list.tests.ps1
# Unit tests for Get-EmulatorList function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'game-emulators.ps1')
}

Describe 'game-emulators.ps1 - Get-EmulatorList' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
    }
    
    Context 'No emulators available' {
        It 'Returns empty array when no emulators are available' {
            # Mock all commands as unavailable
            $allCommands = @('dolphin-dev', 'dolphin-nightly', 'dolphin', 'ryujinx-canary', 'ryujinx', 'retroarch-nightly', 'retroarch')
            foreach ($cmd in $allCommands) {
                Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
            }
            
            $result = Get-EmulatorList
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Some emulators available' {
        It 'Returns list of available emulators' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Setup-AvailableCommandMock -CommandName 'ryujinx-canary'
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            
            $result = Get-EmulatorList
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            
            $dolphin = $result | Where-Object { $_.Name -eq 'Dolphin' }
            $dolphin | Should -Not -BeNullOrEmpty
            $dolphin.Command | Should -Be 'dolphin-dev'
            $dolphin.Category | Should -Be 'Nintendo'
            $dolphin.Available | Should -Be $true
        }
        
        It 'Prefers preferred command variants' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Setup-AvailableCommandMock -CommandName 'dolphin-nightly'
            Setup-AvailableCommandMock -CommandName 'dolphin'
            
            $result = Get-EmulatorList
            
            $dolphin = $result | Where-Object { $_.Name -eq 'Dolphin' }
            $dolphin | Should -Not -BeNullOrEmpty
            $dolphin.Command | Should -Be 'dolphin-dev'
        }
        
        It 'Groups emulators by category' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Setup-AvailableCommandMock -CommandName 'rpcs3'
            Setup-AvailableCommandMock -CommandName 'xemu'
            
            $result = Get-EmulatorList
            
            $nintendo = $result | Where-Object { $_.Category -eq 'Nintendo' }
            $sony = $result | Where-Object { $_.Category -eq 'Sony' }
            $microsoft = $result | Where-Object { $_.Category -eq 'Microsoft' }
            
            $nintendo | Should -Not -BeNullOrEmpty
            $sony | Should -Not -BeNullOrEmpty
            $microsoft | Should -Not -BeNullOrEmpty
        }
    }
}

