# ===============================================
# profile-game-emulators-launch.tests.ps1
# Unit tests for Launch-Game function
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

Describe 'game-emulators.ps1 - Launch-Game' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('dolphin-dev', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('ryujinx-canary', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('retroarch-nightly', [ref]$null)
        }
    }
    
    Context 'ROM file validation' {
        It 'Errors when ROM file does not exist' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.iso' } -MockWith { return $false }
            
            { Launch-Game -RomPath 'nonexistent.iso' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Extension-based emulator selection' {
        It 'Launches GameCube ROM with Dolphin' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'game.gcm' } -MockWith { return $true }
            
            $script:capturedFunction = $null
            Mock Start-Dolphin -MockWith {
                $script:capturedFunction = 'Start-Dolphin'
                $script:capturedRomPath = $RomPath
            }
            
            Launch-Game -RomPath 'game.gcm' -ErrorAction SilentlyContinue
            
            $script:capturedFunction | Should -Be 'Start-Dolphin'
            $script:capturedRomPath | Should -Be 'game.gcm'
        }
        
        It 'Launches Switch ROM with Ryujinx' {
            Setup-AvailableCommandMock -CommandName 'ryujinx-canary'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'game.nsp' } -MockWith { return $true }
            
            $script:capturedFunction = $null
            Mock Start-Ryujinx -MockWith {
                $script:capturedFunction = 'Start-Ryujinx'
                $script:capturedRomPath = $RomPath
            }
            
            Launch-Game -RomPath 'game.nsp' -ErrorAction SilentlyContinue
            
            $script:capturedFunction | Should -Be 'Start-Ryujinx'
            $script:capturedRomPath | Should -Be 'game.nsp'
        }
        
        It 'Launches SNES ROM with RetroArch' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'game.sfc' } -MockWith { return $true }
            
            $script:capturedFunction = $null
            Mock Start-RetroArch -MockWith {
                $script:capturedFunction = 'Start-RetroArch'
                $script:capturedRomPath = $RomPath
            }
            
            Launch-Game -RomPath 'game.sfc' -ErrorAction SilentlyContinue
            
            $script:capturedFunction | Should -Be 'Start-RetroArch'
            $script:capturedRomPath | Should -Be 'game.sfc'
        }
        
        It 'Passes fullscreen flag to emulator' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'game.iso' } -MockWith { return $true }
            
            $script:capturedFullscreen = $false
            Mock Start-Dolphin -MockWith {
                $script:capturedFullscreen = $Fullscreen
            }
            
            Launch-Game -RomPath 'game.iso' -Fullscreen -ErrorAction SilentlyContinue
            
            $script:capturedFullscreen | Should -Be $true
        }
        
        It 'Falls back to RetroArch for unknown extensions' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'game.unknown' } -MockWith { return $true }
            
            $script:capturedFunction = $null
            Mock Start-RetroArch -MockWith {
                $script:capturedFunction = 'Start-RetroArch'
                $script:capturedRomPath = $RomPath
            }
            
            Launch-Game -RomPath 'game.unknown' -ErrorAction SilentlyContinue
            
            $script:capturedFunction | Should -Be 'Start-RetroArch'
            $script:capturedRomPath | Should -Be 'game.unknown'
        }
    }
}

