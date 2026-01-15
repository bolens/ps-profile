# ===============================================
# profile-game-emulators-retroarch.tests.ps1
# Unit tests for Start-RetroArch function
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

Describe 'game-emulators.ps1 - Start-RetroArch' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('retroarch-nightly', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('retroarch', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when retroarch tools are not available' {
            Mock-CommandAvailabilityPester -CommandName 'retroarch-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'retroarch' -Available $false
            Mock Get-Command -ParameterFilter { $Name -in @('retroarch-nightly', 'retroarch') } -MockWith { return $null }
            
            $result = Start-RetroArch -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls retroarch-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            Mock-CommandAvailabilityPester -CommandName 'retroarch-nightly' -Available $true
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-RetroArch -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'retroarch-nightly'
        }
        
        It 'Falls back to retroarch when retroarch-nightly not available' {
            Mock-CommandAvailabilityPester -CommandName 'retroarch-nightly' -Available $false
            Setup-AvailableCommandMock -CommandName 'retroarch'
            Mock-CommandAvailabilityPester -CommandName 'retroarch' -Available $true
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-RetroArch -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'retroarch'
        }
        
        It 'Calls retroarch with core when provided' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-RetroArch -Core 'snes9x' -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.ArgumentList | Should -Contain '-L'
            $script:capturedProcess.ArgumentList | Should -Contain 'snes9x'
        }
        
        It 'Calls retroarch with ROM path when provided' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'game.sfc' } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-RetroArch -RomPath 'game.sfc' -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.ArgumentList | Should -Contain 'game.sfc'
        }
        
        It 'Calls retroarch with fullscreen flag when provided' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-RetroArch -Fullscreen -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.ArgumentList | Should -Contain '--fullscreen'
        }
        
        It 'Errors when ROM path does not exist' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.sfc' } -MockWith { return $false }
            
            { Start-RetroArch -RomPath 'nonexistent.sfc' -ErrorAction Stop } | Should -Throw
        }
    }
}

