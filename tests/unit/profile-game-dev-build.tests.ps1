# ===============================================
# profile-game-dev-build.tests.ps1
# Unit tests for Build-GodotProject function
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

Describe 'game-dev.ps1 - Build-GodotProject' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('godot', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when godot is not available' {
            Mock-CommandAvailabilityPester -CommandName 'godot' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'godot' } -MockWith { return $null }
            
            $result = Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Project path validation' {
        It 'Errors when project path does not exist' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\Nonexistent' } -MockWith { return $false }
            
            { Build-GodotProject -ProjectPath 'C:\Projects\Nonexistent' -ExportPreset 'Windows Desktop' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Build execution' {
        It 'Calls godot with export preset' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\MyGame' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'godot' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Build complete'
            }
            
            $result = Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue
            
            Should -Invoke 'godot' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '--headless'
            $script:capturedArgs | Should -Contain '--path'
            $script:capturedArgs | Should -Contain 'C:\Projects\MyGame'
            $script:capturedArgs | Should -Contain '--export'
            $script:capturedArgs | Should -Contain 'Windows Desktop'
        }
        
        It 'Calls godot with platform when ExportPreset not provided' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\MyGame' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'godot' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Build complete'
            }
            
            $result = Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -Platform 'windows' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--export'
            $script:capturedArgs | Should -Contain 'windows'
        }
        
        It 'Warns when neither ExportPreset nor Platform provided' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\MyGame' } -MockWith { return $true }
            
            $result = Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Creates output directory if it does not exist' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\MyGame' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Output' } -MockWith { return $false }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = 'C:\Output' } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'godot' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Build complete'
            }
            
            $result = Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ExportPreset 'Windows Desktop' -OutputPath 'C:\Output' -ErrorAction SilentlyContinue
            
            Should -Invoke 'New-Item' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'C:\Output'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\MyGame' } -MockWith { return $true }
            
            Mock -CommandName 'godot' -MockWith {
                $global:LASTEXITCODE = 0
                return 'Build complete'
            }
            
            $result = Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ExportPreset 'Windows Desktop' -OutputPath 'C:\Output' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'C:\Output'
        }
        
        It 'Returns project path when OutputPath not provided' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\MyGame' } -MockWith { return $true }
            
            Mock -CommandName 'godot' -MockWith {
                $global:LASTEXITCODE = 0
                return 'Build complete'
            }
            
            $result = Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'C:\Projects\MyGame'
        }
        
        It 'Errors when build fails' {
            Setup-AvailableCommandMock -CommandName 'godot'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Projects\MyGame' } -MockWith { return $true }
            
            Mock -CommandName 'godot' -MockWith {
                $global:LASTEXITCODE = 1
                return 'Build failed'
            }
            
            { Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ExportPreset 'Windows Desktop' -ErrorAction Stop } | Should -Throw
        }
    }
}

