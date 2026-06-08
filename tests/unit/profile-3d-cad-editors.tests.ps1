# ===============================================
# profile-3d-cad-editors.tests.ps1
# Unit tests for 3D/CAD editor functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir '3d-cad.ps1')
}

Describe '3d-cad.ps1 - Editor Functions' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($toolName in @('blender', 'freecad', 'openscad-dev', 'openscad')) {
            if (Get-Command Set-TestCommandAvailabilityState -ErrorAction SilentlyContinue) {
                Set-TestCommandAvailabilityState -CommandName $toolName -Available $false
            }

            Remove-Item -Path "Function:\$toolName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$toolName" -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Launch-Blender' {
        It 'Returns null when blender is not available' {
            Set-TestCommandAvailabilityState -CommandName 'blender' -Available $false

            $result = Launch-Blender -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls blender when available' {
            Set-TestCommandAvailabilityState -CommandName 'blender'

            Launch-Blender -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'blender'
        }

        It 'Calls blender with background flag when provided' {
            Set-TestCommandAvailabilityState -CommandName 'blender'

            Launch-Blender -Background -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--background'
        }

        It 'Calls blender with project path when provided' {
            Set-TestCommandAvailabilityState -CommandName 'blender'
            $projectPath = Join-Path (New-TestTempDirectory -Prefix 'BlenderProject') 'scene.blend'
            New-Item -ItemType File -Path $projectPath -Force | Out-Null

            Launch-Blender -ProjectPath $projectPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $projectPath
        }
    }

    Context 'Launch-FreeCAD' {
        It 'Returns null when freecad is not available' {
            Set-TestCommandAvailabilityState -CommandName 'freecad' -Available $false

            $result = Launch-FreeCAD -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls freecad when available' {
            Set-TestCommandAvailabilityState -CommandName 'freecad'

            Launch-FreeCAD -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'freecad'
        }
    }

    Context 'Launch-OpenSCAD' {
        It 'Returns null when OpenSCAD is not available' {
            Set-TestCommandAvailabilityState -CommandName 'openscad-dev' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'openscad' -Available $false

            $result = Launch-OpenSCAD -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls openscad-dev when available' {
            Set-TestCommandAvailabilityState -CommandName 'openscad-dev'
            $scriptPath = Join-Path (New-TestTempDirectory -Prefix 'OpenScadScript') 'model.scad'
            New-Item -ItemType File -Path $scriptPath -Force | Out-Null

            Launch-OpenSCAD -ScriptPath $scriptPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'openscad-dev'
        }

        It 'Falls back to openscad when openscad-dev not available' {
            Set-TestCommandAvailabilityState -CommandName 'openscad-dev' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'openscad'
            $scriptPath = Join-Path (New-TestTempDirectory -Prefix 'OpenScadFallback') 'model.scad'
            New-Item -ItemType File -Path $scriptPath -Force | Out-Null

            Launch-OpenSCAD -ScriptPath $scriptPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'openscad'
        }

        It 'Calls openscad with output path for rendering' {
            $tempDir = New-TestTempDirectory -Prefix 'OpenScadRender'
            $scriptPath = Join-Path $tempDir 'model.scad'
            $outputPath = Join-Path $tempDir 'model.stl'
            New-Item -ItemType File -Path $scriptPath -Force | Out-Null

            Set-TestCommandAvailabilityState -CommandName 'openscad-dev' -Available $true
            $renderMock = {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)

                $outputIndex = [array]::IndexOf($Arguments, '-o')
                if ($outputIndex -ge 0 -and ($outputIndex + 1) -lt $Arguments.Count) {
                    $renderOutput = $Arguments[$outputIndex + 1]
                    if ($renderOutput) {
                        New-Item -ItemType File -Path $renderOutput -Force | Out-Null
                    }
                }

                $global:LASTEXITCODE = 0
            }
            Set-Item -Path Function:\openscad-dev -Value $renderMock -Force
            Set-Item -Path Function:\global:openscad-dev -Value $renderMock -Force

            $result = Launch-OpenSCAD -ScriptPath $scriptPath -OutputPath $outputPath -ErrorAction SilentlyContinue

            $result | Should -Be $outputPath
        }
    }
}
