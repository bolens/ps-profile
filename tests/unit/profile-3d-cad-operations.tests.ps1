# ===============================================
# profile-3d-cad-operations.tests.ps1
# Unit tests for 3D/CAD operation functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir '3d-cad.ps1')

    $script:TestSceneBlend = Get-TestArtifactPath -FileName 'scene.blend'
    $script:TestRenderPng = Get-TestArtifactPath -FileName 'render.png'
}

Describe '3d-cad.ps1 - Operation Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'blender' -Available $false
        Remove-Item -Path Function:\blender -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:blender -Force -ErrorAction SilentlyContinue
    }

    Context 'Convert-3DFormat' {
        It 'Returns null when blender is not available' {
            Set-TestCommandAvailabilityState -CommandName 'blender' -Available $false

            $result = Convert-3DFormat -InputFile 'model.obj' -OutputFile 'model.stl' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Errors when input file does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'blender'
            $missingInput = Join-Path (New-TestTempDirectory -Prefix 'Convert3DMissing') 'nonexistent.obj'

            { Convert-3DFormat -InputFile $missingInput -OutputFile 'model.stl' -ErrorAction Stop } | Should -Throw
        }

        It 'Calls blender with conversion script' {
            $tempDir = New-TestTempDirectory -Prefix 'Convert3D'
            $inputFile = Join-Path $tempDir 'model.obj'
            $outputFile = Join-Path $tempDir 'model.stl'
            New-Item -ItemType File -Path $inputFile -Force | Out-Null

            Setup-CapturingCommandMock -CommandName 'blender' -ExitCode 0 -OnInvoke (
                {
                    New-Item -ItemType File -Path $outputFile -Force | Out-Null
                }.GetNewClosure()
            )

            $result = Convert-3DFormat -InputFile $inputFile -OutputFile $outputFile -ErrorAction SilentlyContinue

            $result | Should -Be $outputFile
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--background'
            $args | Should -Contain '--python'
        }

        It 'Creates output directory if it does not exist' {
            $tempDir = New-TestTempDirectory -Prefix 'Convert3DOutputDir'
            $inputFile = Join-Path $tempDir 'model.obj'
            $outputDir = Join-Path $tempDir 'nested' 'output'
            $outputFile = Join-Path $outputDir 'model.stl'
            New-Item -ItemType File -Path $inputFile -Force | Out-Null

            Setup-CapturingCommandMock -CommandName 'blender' -ExitCode 0 -OnInvoke (
                {
                    New-Item -ItemType File -Path $outputFile -Force | Out-Null
                }.GetNewClosure()
            )

            Convert-3DFormat -InputFile $inputFile -OutputFile $outputFile -ErrorAction SilentlyContinue | Out-Null

            Test-Path -LiteralPath $outputDir | Should -Be $true
        }
    }

    Context 'Render-3DScene' {
        It 'Returns null when blender is not available' {
            Set-TestCommandAvailabilityState -CommandName 'blender' -Available $false

            $result = Render-3DScene -ProjectPath $script:TestSceneBlend -OutputPath $script:TestRenderPng -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Errors when project file does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'blender'
            $missingProject = Join-Path (New-TestTempDirectory -Prefix 'Render3DMissing') 'nonexistent.blend'

            { Render-3DScene -ProjectPath $missingProject -OutputPath $script:TestRenderPng -ErrorAction Stop } | Should -Throw
        }

        It 'Calls blender with render arguments' {
            $tempDir = New-TestTempDirectory -Prefix 'Render3D'
            $projectPath = Join-Path $tempDir 'scene.blend'
            $outputPath = Join-Path $tempDir 'render.png'
            New-Item -ItemType File -Path $projectPath -Force | Out-Null

            $global:TestExpectedOutputFile = $outputPath
            Setup-CapturingCommandMock -CommandName 'blender' -ExitCode 0 -OnInvoke {
                New-Item -ItemType File -Path $global:TestExpectedOutputFile -Force | Out-Null
            }

            $result = Render-3DScene -ProjectPath $projectPath -OutputPath $outputPath -ErrorAction SilentlyContinue

            $result | Should -Be $outputPath
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--background'
            $args | Should -Contain $projectPath
            $args | Should -Contain '--render-output'
            $args | Should -Contain $outputPath
            $args | Should -Contain '--engine'
        }

        It 'Calls blender with frame number when provided' {
            $tempDir = New-TestTempDirectory -Prefix 'Render3DFrame'
            $projectPath = Join-Path $tempDir 'scene.blend'
            $outputPath = Join-Path $tempDir 'render.png'
            New-Item -ItemType File -Path $projectPath -Force | Out-Null

            $global:TestExpectedOutputFile = $outputPath
            Setup-CapturingCommandMock -CommandName 'blender' -ExitCode 0 -OnInvoke {
                New-Item -ItemType File -Path $global:TestExpectedOutputFile -Force | Out-Null
            }

            Render-3DScene -ProjectPath $projectPath -OutputPath $outputPath -Frame 10 -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--frame'
            $args | Should -Contain '10'
        }

        It 'Calls blender with specified engine' {
            $tempDir = New-TestTempDirectory -Prefix 'Render3DEngine'
            $projectPath = Join-Path $tempDir 'scene.blend'
            $outputPath = Join-Path $tempDir 'render.png'
            New-Item -ItemType File -Path $projectPath -Force | Out-Null

            $global:TestExpectedOutputFile = $outputPath
            Setup-CapturingCommandMock -CommandName 'blender' -ExitCode 0 -OnInvoke {
                New-Item -ItemType File -Path $global:TestExpectedOutputFile -Force | Out-Null
            }

            Render-3DScene -ProjectPath $projectPath -OutputPath $outputPath -Engine 'eevee' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--engine'
            $args | Should -Contain 'eevee'
        }
    }
}
