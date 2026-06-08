# ===============================================
# profile-game-emulators-dolphin.tests.ps1
# Unit tests for Start-Dolphin function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'game-emulators.ps1')
}

Describe 'game-emulators.ps1 - Start-Dolphin' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($toolName in @('dolphin-dev', 'dolphin-nightly', 'dolphin')) {
            Set-TestCommandAvailabilityState -CommandName $toolName -Available $false
            Remove-Item -Path "Function:\$toolName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$toolName" -Force -ErrorAction SilentlyContinue
        }

        Reset-TestStartProcessMock
    }

    Context 'Tool not available' {
        It 'Returns null when dolphin tools are not available' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'dolphin-nightly' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'dolphin' -Available $false

            $result = Start-Dolphin -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls dolphin-dev when available' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev'

            Start-Dolphin -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'dolphin-dev'
        }

        It 'Falls back to dolphin-nightly when dolphin-dev not available' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'dolphin-nightly'

            Start-Dolphin -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'dolphin-nightly'
        }

        It 'Falls back to dolphin when dolphin-dev and dolphin-nightly not available' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'dolphin-nightly' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'dolphin'

            Start-Dolphin -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'dolphin'
        }

        It 'Calls dolphin with ROM path when provided' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev'
            $romPath = Join-Path (New-TestTempDirectory -Prefix 'DolphinRom') 'game.iso'
            New-Item -ItemType File -Path $romPath -Force | Out-Null

            Start-Dolphin -RomPath $romPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $romPath
        }

        It 'Calls dolphin with fullscreen flag when provided' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev'

            Start-Dolphin -Fullscreen -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--fullscreen'
        }

        It 'Returns null when ROM path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev'
            $missingRom = Join-Path (New-TestTempDirectory -Prefix 'DolphinMissingRom') 'nonexistent.iso'

            $result = Start-Dolphin -RomPath $missingRom -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }

        It 'Handles Start-Process errors gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev'
            Set-TestStartProcessFailure -Message 'Process start failed'

            { Start-Dolphin -ErrorAction Stop } | Should -Throw '*Process start failed*'
        }
    }
}
