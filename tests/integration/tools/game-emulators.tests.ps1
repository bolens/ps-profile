# ===============================================
# game-emulators.tests.ps1
# Integration tests for game-emulators.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'game-emulators.ps1 - Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 'game-emulators.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 'game-emulators.ps1')
                . (Join-Path $script:ProfileDir 'game-emulators.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
        }
        
        It 'Registers Start-Dolphin function' {
            Get-Command -Name 'Start-Dolphin' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Start-Ryujinx function' {
            Get-Command -Name 'Start-Ryujinx' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Start-RetroArch function' {
            Get-Command -Name 'Start-RetroArch' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-EmulatorList function' {
            Get-Command -Name 'Get-EmulatorList' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Game function' {
            Get-Command -Name 'Launch-Game' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
        }
        
        It 'Start-Dolphin handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            # Mock commands as unavailable
            Mock-CommandAvailabilityPester -CommandName 'dolphin-dev' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'dolphin-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'dolphin' -Available $false
            
            { Start-Dolphin -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Start-Ryujinx handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'ryujinx-canary' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'ryujinx' -Available $false
            
            { Start-Ryujinx -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Start-RetroArch handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'retroarch-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'retroarch' -Available $false
            
            { Start-RetroArch -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Get-EmulatorList returns empty list when no emulators available' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            # Mock all commands as unavailable
            $allCommands = @('dolphin-dev', 'dolphin-nightly', 'dolphin', 'ryujinx-canary', 'ryujinx', 'retroarch-nightly', 'retroarch')
            foreach ($cmd in $allCommands) {
                Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
            }
            
            $result = Get-EmulatorList
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Launch-Game handles missing ROM file gracefully' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.iso' } -MockWith { return $false }
            
            { Launch-Game -RomPath 'nonexistent.iso' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Function Behavior' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
        }
        
        It 'Get-EmulatorList returns array of emulator objects' {
            $result = Get-EmulatorList
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Array]
            
            if ($result.Count -gt 0) {
                $result[0] | Should -HaveMember 'Name'
                $result[0] | Should -HaveMember 'Category'
                $result[0] | Should -HaveMember 'Command'
                $result[0] | Should -HaveMember 'Available'
            }
        }
    }
}

