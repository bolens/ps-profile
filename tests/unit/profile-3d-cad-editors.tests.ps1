# ===============================================
# profile-3d-cad-editors.tests.ps1
# Unit tests for 3D/CAD editor functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir '3d-cad.ps1')
}

Describe '3d-cad.ps1 - Editor Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('blender', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('freecad', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('openscad-dev', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('openscad', [ref]$null)
        }
    }
    
    Context 'Launch-Blender' {
        It 'Returns null when blender is not available' {
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'blender' } -MockWith { return $null }
            
            $result = Launch-Blender -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls blender when available' {
            Setup-AvailableCommandMock -CommandName 'blender'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Blender -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'blender'
        }
        
        It 'Calls blender with background flag when provided' {
            Setup-AvailableCommandMock -CommandName 'blender'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Blender -Background -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--background'
        }
        
        It 'Calls blender with project path when provided' {
            Setup-AvailableCommandMock -CommandName 'blender'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'scene.blend' } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-Blender -ProjectPath 'scene.blend' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain 'scene.blend'
        }
    }
    
    Context 'Launch-FreeCAD' {
        It 'Returns null when freecad is not available' {
            Mock-CommandAvailabilityPester -CommandName 'freecad' -Available $false
            
            $result = Launch-FreeCAD -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls freecad when available' {
            Setup-AvailableCommandMock -CommandName 'freecad'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-FreeCAD -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'freecad'
        }
    }
    
    Context 'Launch-OpenSCAD' {
        It 'Returns null when OpenSCAD is not available' {
            Mock-CommandAvailabilityPester -CommandName 'openscad-dev' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'openscad' -Available $false
            
            $result = Launch-OpenSCAD -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls openscad-dev when available' {
            Setup-AvailableCommandMock -CommandName 'openscad-dev'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-OpenSCAD -ScriptPath 'model.scad' -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'openscad-dev'
        }
        
        It 'Falls back to openscad when openscad-dev not available' {
            Mock-CommandAvailabilityPester -CommandName 'openscad-dev' -Available $false
            Setup-AvailableCommandMock -CommandName 'openscad'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Launch-OpenSCAD -ScriptPath 'model.scad' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'openscad'
        }
        
        It 'Calls openscad with output path for rendering' {
            Setup-AvailableCommandMock -CommandName 'openscad-dev'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'model.scad' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'model.stl' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'openscad-dev' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Rendering complete'
            }
            
            $result = Launch-OpenSCAD -ScriptPath 'model.scad' -OutputPath 'model.stl' -ErrorAction SilentlyContinue
            
            Should -Invoke 'openscad-dev' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'model.stl'
        }
    }
}

