# ===============================================
# profile-game-dev-editors.tests.ps1
# Unit tests for game development editor functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'game-dev.ps1')
}

Describe 'game-dev.ps1 - Editor Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('blockbench', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('tiled', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('godot', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('unity-hub', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('unity', [ref]$null)
        }
    }
    
    Context 'Launch-Blockbench' {
        It 'Returns null when blockbench is not available' {
            Mock-CommandAvailabilityPester -CommandName 'blockbench' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'blockbench' } -MockWith { return $null }
            
            $result = Launch-Blockbench -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls blockbench when available' {
            Setup-AvailableCommandMock -CommandName 'blockbench'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Blockbench -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'blockbench'
        }
        
        It 'Calls blockbench with project path when provided' {
            Setup-AvailableCommandMock -CommandName 'blockbench'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'model.bbmodel' } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Blockbench -ProjectPath 'model.bbmodel' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain 'model.bbmodel'
        }
        
        It 'Errors when project path does not exist' {
            Setup-AvailableCommandMock -CommandName 'blockbench'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.bbmodel' } -MockWith { return $false }
            
            { Launch-Blockbench -ProjectPath 'nonexistent.bbmodel' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Launch-Tiled' {
        It 'Returns null when tiled is not available' {
            Mock-CommandAvailabilityPester -CommandName 'tiled' -Available $false
            
            $result = Launch-Tiled -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls tiled when available' {
            Setup-AvailableCommandMock -CommandName 'tiled'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Tiled -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'tiled'
        }
        
        It 'Calls tiled with map path when provided' {
            Setup-AvailableCommandMock -CommandName 'tiled'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'map.tmx' } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Tiled -ProjectPath 'map.tmx' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain 'map.tmx'
        }
    }
    
    Context 'Launch-Godot' {
        It 'Returns null when godot is not available' {
            Mock-CommandAvailabilityPester -CommandName 'godot' -Available $false
            
            $result = Launch-Godot -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls godot when available' {
            Setup-AvailableCommandMock -CommandName 'godot'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Godot -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'godot'
        }
        
        It 'Calls godot with headless flag when provided' {
            Setup-AvailableCommandMock -CommandName 'godot'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Godot -Headless -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--headless'
        }
        
        It 'Calls godot with project path when provided' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\MyGame' } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Godot -ProjectPath 'C:\Projects\MyGame' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--path'
            $script:capturedProcess.ArgumentList | Should -Contain 'C:\Projects\MyGame'
        }
    }
    
    Context 'Launch-Unity' {
        It 'Returns null when Unity is not available' {
            Mock-CommandAvailabilityPester -CommandName 'unity-hub' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'unity' -Available $false
            
            $result = Launch-Unity -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls unity-hub when available' {
            Setup-AvailableCommandMock -CommandName 'unity-hub'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Unity -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'unity-hub'
        }
        
        It 'Falls back to unity when unity-hub not available' {
            Mock-CommandAvailabilityPester -CommandName 'unity-hub' -Available $false
            Setup-AvailableCommandMock -CommandName 'unity'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Unity -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'unity'
        }
    }
}

