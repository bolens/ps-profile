# ===============================================
# 3d-cad.tests.ps1
# Integration tests for 3d-cad.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe '3d-cad.ps1 - Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir '3d-cad.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir '3d-cad.ps1')
                . (Join-Path $script:ProfileDir '3d-cad.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '3d-cad.ps1')
        }
        
        It 'Registers Launch-Blender function' {
            Get-Command -Name 'Launch-Blender' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-FreeCAD function' {
            Get-Command -Name 'Launch-FreeCAD' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-OpenSCAD function' {
            Get-Command -Name 'Launch-OpenSCAD' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Convert-3DFormat function' {
            Get-Command -Name 'Convert-3DFormat' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Render-3DScene function' {
            Get-Command -Name 'Render-3DScene' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '3d-cad.ps1')
        }
        
        It 'Launch-Blender handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false
            
            { Launch-Blender -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-FreeCAD handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'freecad' -Available $false
            
            { Launch-FreeCAD -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-OpenSCAD handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'openscad-dev' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'openscad' -Available $false
            
            { Launch-OpenSCAD -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Convert-3DFormat handles missing blender gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false
            
            $result = Convert-3DFormat -InputFile 'model.obj' -OutputFile 'model.stl' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
        
        It 'Render-3DScene handles missing blender gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false
            
            $result = Render-3DScene -ProjectPath 'scene.blend' -OutputPath 'render.png' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }
}

