# ===============================================
# profile-game-dev-build.tests.ps1
# Unit tests for Build-GodotProject function
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'game-dev.ps1')

    $script:TestProjectDir = New-TestTempDirectory -Prefix 'GodotBuildProject'
    $script:TestOutputDir = New-TestTempDirectory -Prefix 'GodotBuildOutput'
}

Describe 'game-dev.ps1 - Build-GodotProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'godot' -Available $false
        Remove-Item -Path Function:\godot -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:godot -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when godot is not available' {
            Set-TestCommandAvailabilityState -CommandName 'godot' -Available $false

            $result = Build-GodotProject -ProjectPath $script:TestProjectDir -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Project path validation' {
        It 'Returns null when project path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'godot'
            $missingProject = Join-Path (New-TestTempDirectory -Prefix 'GodotMissingProject') 'nonexistent'

            $result = Build-GodotProject -ProjectPath $missingProject -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Build execution' {
        It 'Calls godot with export preset' {
            Setup-CapturingCommandMock -CommandName 'godot' -Output 'Build complete'

            $result = Build-GodotProject -ProjectPath $script:TestProjectDir -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--headless'
            $args | Should -Contain '--path'
            $args | Should -Contain $script:TestProjectDir
            $args | Should -Contain '--export'
            $args | Should -Contain 'Windows Desktop'
        }

        It 'Calls godot with platform when ExportPreset not provided' {
            Setup-CapturingCommandMock -CommandName 'godot' -Output 'Build complete'

            Build-GodotProject -ProjectPath $script:TestProjectDir -Platform 'windows' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--export'
            $args | Should -Contain 'windows'
        }

        It 'Warns when neither ExportPreset nor Platform provided' {
            Set-TestCommandAvailabilityState -CommandName 'godot'

            $result = Build-GodotProject -ProjectPath $script:TestProjectDir -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Creates output directory if it does not exist' {
            Setup-CapturingCommandMock -CommandName 'godot' -Output 'Build complete'
            $newOutputDir = Join-Path (New-TestTempDirectory -Prefix 'GodotBuildOutputParent') 'nested-output'

            Build-GodotProject -ProjectPath $script:TestProjectDir -ExportPreset 'Windows Desktop' -OutputPath $newOutputDir -ErrorAction SilentlyContinue | Out-Null

            Test-Path -LiteralPath $newOutputDir | Should -Be $true
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $newOutputDir
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'godot' -Output 'Build complete'

            $result = Build-GodotProject -ProjectPath $script:TestProjectDir -ExportPreset 'Windows Desktop' -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue

            $result | Should -Be $script:TestOutputDir
        }

        It 'Returns project path when OutputPath not provided' {
            Setup-CapturingCommandMock -CommandName 'godot' -Output 'Build complete'

            $result = Build-GodotProject -ProjectPath $script:TestProjectDir -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue

            $result | Should -Be $script:TestProjectDir
        }

        It 'Errors when build fails' {
            Setup-CapturingCommandMock -CommandName 'godot' -Output 'Build failed' -ExitCode 1

            { Build-GodotProject -ProjectPath $script:TestProjectDir -ExportPreset 'Windows Desktop' -ErrorAction Stop } | Should -Throw '*Godot build failed*'
        }
    }
}
