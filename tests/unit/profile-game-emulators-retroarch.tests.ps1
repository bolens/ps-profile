# ===============================================
# profile-game-emulators-retroarch.tests.ps1
# Unit tests for Start-RetroArch function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'game-emulators.ps1')
}

Describe 'game-emulators.ps1 - Start-RetroArch' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($toolName in @('retroarch-nightly', 'retroarch')) {
            Set-TestCommandAvailabilityState -CommandName $toolName -Available $false
            Remove-Item -Path "Function:\$toolName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$toolName" -Force -ErrorAction SilentlyContinue
        }

        Reset-TestStartProcessMock
    }

    Context 'Tool not available' {
        It 'Returns null when retroarch tools are not available' {
            Set-TestCommandAvailabilityState -CommandName 'retroarch-nightly' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'retroarch' -Available $false

            $result = Start-RetroArch -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls retroarch-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'

            Start-RetroArch -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'retroarch-nightly'
        }

        It 'Falls back to retroarch when retroarch-nightly not available' {
            Set-TestCommandAvailabilityState -CommandName 'retroarch-nightly' -Available $false
            Setup-AvailableCommandMock -CommandName 'retroarch'

            Start-RetroArch -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'retroarch'
        }

        It 'Calls retroarch with core when provided' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'

            Start-RetroArch -Core 'snes9x' -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '-L'
            $capture.ArgumentList | Should -Contain 'snes9x'
        }

        It 'Calls retroarch with ROM path when provided' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            $romPath = Join-Path (New-TestTempDirectory -Prefix 'RetroArchRom') 'game.sfc'
            New-Item -ItemType File -Path $romPath -Force | Out-Null

            Start-RetroArch -RomPath $romPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $romPath
        }

        It 'Calls retroarch with fullscreen flag when provided' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'

            Start-RetroArch -Fullscreen -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--fullscreen'
        }

        It 'Errors when ROM path does not exist' {
            Setup-AvailableCommandMock -CommandName 'retroarch-nightly'
            $missingRom = Join-Path (New-TestTempDirectory -Prefix 'RetroArchMissingRom') 'nonexistent.sfc'

            $result = Start-RetroArch -RomPath $missingRom -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }
    }
}
