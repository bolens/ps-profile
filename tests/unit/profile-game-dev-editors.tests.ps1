# ===============================================
# profile-game-dev-editors.tests.ps1
# Unit tests for game development editor functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'game-dev.ps1')

    $script:TestProjectDir = New-TestTempDirectory -Prefix 'GodotProject'
    $script:TestModelFile = Join-Path (New-TestTempDirectory -Prefix 'BlockbenchModel') 'model.bbmodel'
    Set-Content -Path $script:TestModelFile -Value '{}'
    $script:TestMapFile = Join-Path (New-TestTempDirectory -Prefix 'TiledMap') 'map.tmx'
    Set-Content -Path $script:TestMapFile -Value '<?xml version="1.0"?><map></map>'
}

Describe 'game-dev.ps1 - Editor Functions' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($command in @('blockbench', 'tiled', 'godot', 'unity-hub', 'unity')) {
            Set-TestCommandAvailabilityState -CommandName $command -Available $false
            Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue
        }

        Reset-TestStartProcessMock
    }

    Context 'Launch-Blockbench' {
        It 'Returns null when blockbench is not available' {
            $result = Launch-Blockbench -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls blockbench when available' {
            Set-TestCommandAvailabilityState -CommandName 'blockbench'

            Launch-Blockbench -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'blockbench'
        }

        It 'Calls blockbench with project path when provided' {
            Set-TestCommandAvailabilityState -CommandName 'blockbench'

            Launch-Blockbench -ProjectPath $script:TestModelFile -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $script:TestModelFile
        }

        It 'Returns null when project path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'blockbench'
            $missingPath = Join-Path (New-TestTempDirectory -Prefix 'BlockbenchMissing') 'nonexistent.bbmodel'

            $result = Launch-Blockbench -ProjectPath $missingPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }
    }

    Context 'Launch-Tiled' {
        It 'Returns null when tiled is not available' {
            $result = Launch-Tiled -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls tiled when available' {
            Set-TestCommandAvailabilityState -CommandName 'tiled'

            Launch-Tiled -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'tiled'
        }

        It 'Calls tiled with map path when provided' {
            Set-TestCommandAvailabilityState -CommandName 'tiled'

            Launch-Tiled -ProjectPath $script:TestMapFile -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $script:TestMapFile
        }
    }

    Context 'Launch-Godot' {
        It 'Returns null when godot is not available' {
            $result = Launch-Godot -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls godot when available' {
            Set-TestCommandAvailabilityState -CommandName 'godot'

            Launch-Godot -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'godot'
        }

        It 'Calls godot with headless flag when provided' {
            Set-TestCommandAvailabilityState -CommandName 'godot'

            Launch-Godot -Headless -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--headless'
        }

        It 'Calls godot with project path when provided' {
            Set-TestCommandAvailabilityState -CommandName 'godot'

            Launch-Godot -ProjectPath $script:TestProjectDir -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--path'
            $capture.ArgumentList | Should -Contain $script:TestProjectDir
        }
    }

    Context 'Launch-Unity' {
        It 'Returns null when Unity is not available' {
            $result = Launch-Unity -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls unity-hub when available' {
            Set-TestCommandAvailabilityState -CommandName 'unity-hub'

            Launch-Unity -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'unity-hub'
        }

        It 'Falls back to unity when unity-hub not available' {
            Set-TestCommandAvailabilityState -CommandName 'unity'
            Mark-TestCommandsUnavailable -CommandNames 'unity-hub'

            Launch-Unity -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'unity'
        }
    }
}
