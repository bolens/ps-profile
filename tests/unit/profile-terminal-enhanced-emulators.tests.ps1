# ===============================================
# profile-terminal-enhanced-emulators.tests.ps1
# Unit tests for terminal emulator functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')

    $script:TestWorkingDirectory = New-TestTempDirectory -Prefix 'AlacrittyWd'
}

Describe 'terminal-enhanced.ps1 - Terminal Emulator Functions' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($command in @('alacritty', 'kitty', 'wezterm-nightly', 'wezterm', 'tabby')) {
            Set-TestCommandAvailabilityState -CommandName $command -Available $false
            Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Launch-Alacritty' {
        It 'Returns null when alacritty is not available' {
            $result = Launch-Alacritty -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls alacritty when available' {
            Setup-AvailableCommandMock -CommandName 'alacritty'

            Launch-Alacritty -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'alacritty'
        }

        It 'Calls alacritty with command when provided' {
            Setup-AvailableCommandMock -CommandName 'alacritty'

            Launch-Alacritty -Command 'git status' -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '-e'
            $capture.ArgumentList | Should -Contain 'git status'
        }

        It 'Calls alacritty with working directory when provided' {
            Setup-AvailableCommandMock -CommandName 'alacritty'

            Launch-Alacritty -WorkingDirectory $script:TestWorkingDirectory -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--working-directory'
            $capture.ArgumentList | Should -Contain $script:TestWorkingDirectory
        }
    }

    Context 'Launch-Kitty' {
        It 'Returns null when kitty is not available' {
            $result = Launch-Kitty -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls kitty when available' {
            Setup-AvailableCommandMock -CommandName 'kitty'

            Launch-Kitty -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'kitty'
        }
    }

    Context 'Launch-WezTerm' {
        It 'Returns null when WezTerm is not available' {
            Mark-TestCommandsUnavailable -CommandNames @('wezterm-nightly', 'wezterm')

            $result = Launch-WezTerm -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls wezterm-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'wezterm-nightly'

            Launch-WezTerm -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'wezterm-nightly'
        }

        It 'Falls back to wezterm when wezterm-nightly not available' {
            Mark-TestCommandsUnavailable -CommandNames 'wezterm-nightly'
            Setup-AvailableCommandMock -CommandName 'wezterm'

            Launch-WezTerm -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'wezterm'
        }
    }

    Context 'Launch-Tabby' {
        It 'Returns null when tabby is not available' {
            $result = Launch-Tabby -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls tabby when available' {
            Setup-AvailableCommandMock -CommandName 'tabby'

            Launch-Tabby -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'tabby'
        }
    }
}
