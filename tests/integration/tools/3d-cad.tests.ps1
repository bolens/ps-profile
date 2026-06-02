# ===============================================
# 3d-cad.tests.ps1
# Integration tests for 3d-cad.ps1 module
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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
        BeforeEach {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
        }

        BeforeAll {
            . (Join-Path $script:ProfileDir '3d-cad.ps1')
        }

        It 'Launch-Blender handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false

            $output = & { Launch-Blender -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'blender not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'blender'
        }

        It 'Launch-FreeCAD handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'freecad' -Available $false

            $output = & { Launch-FreeCAD -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'freecad not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'freecad'
        }

        It 'Launch-OpenSCAD handles missing tools gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'openscad-dev' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'openscad' -Available $false

            $output = & { Launch-OpenSCAD -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'openscad-dev not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'openscad-dev'
        }

        It 'Convert-3DFormat handles missing blender gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false

            $output = & {
                Convert-3DFormat -InputFile 'model.obj' -OutputFile 'model.stl' -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'blender not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'blender'
        }

        It 'Render-3DScene handles missing blender gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'blender' -Available $false

            $output = & {
                Render-3DScene -ProjectPath (Get-TestArtifactPath -FileName 'scene.blend') -OutputPath (Get-TestArtifactPath -FileName 'render.png') -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'blender not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'blender'
        }
    }
}

