# ===============================================
# profile-3d-cad-operations.tests.ps1
# Unit tests for 3D/CAD operation functions
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

Describe '3d-cad.ps1 - Operation Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('blender', [ref]$null)
        }
    }
    
    Context 'Convert-3DFormat' {
        It 'Returns null when blender is not available' {
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false
            
            $result = Convert-3DFormat -InputFile 'model.obj' -OutputFile 'model.stl' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Errors when input file does not exist' {
            Setup-AvailableCommandMock -CommandName 'blender'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.obj' } -MockWith { return $false }
            
            { Convert-3DFormat -InputFile 'nonexistent.obj' -OutputFile 'model.stl' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Calls blender with conversion script' {
            Setup-AvailableCommandMock -CommandName 'blender'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'model.obj' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'model.stl' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*blender_convert_*.py' } -MockWith { return $true }
            Mock Set-Content -MockWith { }
            Mock Remove-Item -MockWith { }
            
            $script:capturedArgs = @()
            Mock -CommandName 'blender' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Conversion complete'
            }
            
            $result = Convert-3DFormat -InputFile 'model.obj' -OutputFile 'model.stl' -ErrorAction SilentlyContinue
            
            Should -Invoke 'blender' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '--background'
            $script:capturedArgs | Should -Contain '--python'
        }
        
        It 'Creates output directory if it does not exist' {
            Setup-AvailableCommandMock -CommandName 'blender'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'model.obj' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Output\model.stl' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'C:\Output' } -MockWith { return $false }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = 'C:\Output' } }
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*blender_convert_*.py' } -MockWith { return $true }
            Mock Set-Content -MockWith { }
            Mock Remove-Item -MockWith { }
            
            Mock -CommandName 'blender' -MockWith {
                $global:LASTEXITCODE = 0
                return 'Conversion complete'
            }
            
            Convert-3DFormat -InputFile 'model.obj' -OutputFile 'C:\Output\model.stl' -ErrorAction SilentlyContinue
            
            Should -Invoke 'New-Item' -Times 1 -Exactly
        }
    }
    
    Context 'Render-3DScene' {
        It 'Returns null when blender is not available' {
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false
            
            $result = Render-3DScene -ProjectPath 'scene.blend' -OutputPath 'render.png' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Errors when project file does not exist' {
            Setup-AvailableCommandMock -CommandName 'blender'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.blend' } -MockWith { return $false }
            
            { Render-3DScene -ProjectPath 'nonexistent.blend' -OutputPath 'render.png' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Calls blender with render arguments' {
            Setup-AvailableCommandMock -CommandName 'blender'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'scene.blend' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'render.png' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'blender' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Render complete'
            }
            
            $result = Render-3DScene -ProjectPath 'scene.blend' -OutputPath 'render.png' -ErrorAction SilentlyContinue
            
            Should -Invoke 'blender' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain '--background'
            $script:capturedArgs | Should -Contain 'scene.blend'
            $script:capturedArgs | Should -Contain '--render-output'
            $script:capturedArgs | Should -Contain 'render.png'
            $script:capturedArgs | Should -Contain '--engine'
        }
        
        It 'Calls blender with frame number when provided' {
            Setup-AvailableCommandMock -CommandName 'blender'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'scene.blend' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'render.png' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'blender' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Render complete'
            }
            
            Render-3DScene -ProjectPath 'scene.blend' -OutputPath 'render.png' -Frame 10 -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--frame'
            $script:capturedArgs | Should -Contain '10'
        }
        
        It 'Calls blender with specified engine' {
            Setup-AvailableCommandMock -CommandName 'blender'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'scene.blend' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'render.png' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'blender' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Render complete'
            }
            
            Render-3DScene -ProjectPath 'scene.blend' -OutputPath 'render.png' -Engine 'eevee' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--engine'
            $script:capturedArgs | Should -Contain 'eevee'
        }
    }
}

