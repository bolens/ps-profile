# ===============================================
# profile-game-emulators-dolphin.tests.ps1
# Unit tests for Start-Dolphin function
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

Describe 'game-emulators.ps1 - Start-Dolphin' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('dolphin-dev', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('dolphin-nightly', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('dolphin', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when dolphin tools are not available' {
            Mock-CommandAvailabilityPester -CommandName 'dolphin-dev' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'dolphin-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'dolphin' -Available $false
            Mock Get-Command -ParameterFilter { $Name -in @('dolphin-dev', 'dolphin-nightly', 'dolphin') } -MockWith { return $null }
            
            $result = Start-Dolphin -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls dolphin-dev when available' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Mock-CommandAvailabilityPester -CommandName 'dolphin-dev' -Available $true
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-Dolphin -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'dolphin-dev'
        }
        
        It 'Falls back to dolphin-nightly when dolphin-dev not available' {
            Mock-CommandAvailabilityPester -CommandName 'dolphin-dev' -Available $false
            Setup-AvailableCommandMock -CommandName 'dolphin-nightly'
            Mock-CommandAvailabilityPester -CommandName 'dolphin-nightly' -Available $true
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-Dolphin -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'dolphin-nightly'
        }
        
        It 'Falls back to dolphin when dolphin-dev and dolphin-nightly not available' {
            Mock-CommandAvailabilityPester -CommandName 'dolphin-dev' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'dolphin-nightly' -Available $false
            Setup-AvailableCommandMock -CommandName 'dolphin'
            Mock-CommandAvailabilityPester -CommandName 'dolphin' -Available $true
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-Dolphin -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'dolphin'
        }
        
        It 'Calls dolphin with ROM path when provided' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'game.iso' } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-Dolphin -RomPath 'game.iso' -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.ArgumentList | Should -Contain 'game.iso'
        }
        
        It 'Calls dolphin with fullscreen flag when provided' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-Dolphin -Fullscreen -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.ArgumentList | Should -Contain '--fullscreen'
        }
        
        It 'Errors when ROM path does not exist' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.iso' } -MockWith { return $false }
            
            { Start-Dolphin -RomPath 'nonexistent.iso' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Handles Start-Process errors gracefully' {
            Setup-AvailableCommandMock -CommandName 'dolphin-dev'
            Mock Start-Process -MockWith { throw "Process start failed" }
            
            { Start-Dolphin -ErrorAction Stop } | Should -Throw
        }
    }
}

