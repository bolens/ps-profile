# ===============================================
# profile-terminal-enhanced-multiplexer.tests.ps1
# Unit tests for terminal multiplexer functions
# ===============================================

function global:Get-TestCommandCaptureFlatAt {
    param(
        [int]$Index = 0
    )

    if (-not $global:TestCommandInvocationCaptures -or $global:TestCommandInvocationCaptures.Count -le $Index) {
        return @()
    }

    $flatArgs = [System.Collections.Generic.List[object]]::new()
    foreach ($arg in $global:TestCommandInvocationCaptures[$Index]) {
        if ($arg -is [System.Array]) {
            foreach ($nestedArg in $arg) {
                $flatArgs.Add($nestedArg)
            }
        }
        else {
            $flatArgs.Add($arg)
        }
    }

    return ,@($flatArgs.ToArray())
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
}

Describe 'terminal-enhanced.ps1 - Multiplexer Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'tmux' -Available $false
        Remove-Item -Path 'Function:\tmux' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:tmux' -Force -ErrorAction SilentlyContinue
    }

    Context 'Start-Tmux' {
        It 'Returns null when tmux is not available' {
            $result = Start-Tmux -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Creates new tmux session when no session name provided' {
            Setup-CapturingCommandMock -CommandName 'tmux' -Output 'Session created'

            Start-Tmux -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 2
            $firstArgs = Get-TestCommandCaptureFlatAt -Index 0
            $firstArgs | Should -Contain 'new-session'
            $firstArgs | Should -Contain '-d'
        }

        It 'Creates named tmux session' {
            Setup-CapturingCommandMock -CommandName 'tmux' -Output 'Session created'

            $result = Start-Tmux -SessionName 'dev' -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 2
            $firstArgs = Get-TestCommandCaptureFlatAt -Index 0
            $firstArgs | Should -Contain 'new-session'
            $firstArgs | Should -Contain '-s'
            $firstArgs | Should -Contain 'dev'
            @($result)[-1] | Should -Be 'dev'
        }

        It 'Attaches to existing session when Attach specified' {
            Setup-CapturingCommandMock -CommandName 'tmux' -OnInvoke {
                $flatArgs = Get-TestCommandInvocationArgsFlat
                if ($flatArgs -contains 'list-sessions') {
                    return 'dev'
                }

                return 'Session attached'
            }

            $result = Start-Tmux -SessionName 'dev' -Attach -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 2
            $lastArgs = Get-TestCommandCaptureFlatAt -Index 1
            $lastArgs | Should -Contain 'attach-session'
            @($result)[-1] | Should -Be 'dev'
        }

        It 'Creates new session when Attach specified but session does not exist' {
            Setup-CapturingCommandMock -CommandName 'tmux' -OnInvoke {
                $flatArgs = Get-TestCommandInvocationArgsFlat
                if ($flatArgs -contains 'list-sessions') {
                    return ''
                }

                return 'Session created'
            }

            $result = Start-Tmux -SessionName 'dev' -Attach -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 3
            $createArgs = Get-TestCommandCaptureFlatAt -Index 1
            $createArgs | Should -Contain 'new-session'
            @($result)[-1] | Should -Be 'dev'
        }

        It 'Executes command in new session' {
            Setup-CapturingCommandMock -CommandName 'tmux' -Output 'Session created'

            Start-Tmux -SessionName 'dev' -Command 'npm start' -ErrorAction SilentlyContinue | Out-Null

            $firstArgs = Get-TestCommandCaptureFlatAt -Index 0
            $firstArgs | Should -Contain 'npm start'
        }
    }

    Context 'Get-TerminalInfo' {
        BeforeEach {
            Clear-TestCommandInvocationCapture

            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            $terminalCommands = @(
                'alacritty', 'kitty', 'wezterm-nightly', 'wezterm', 'tabby',
                'wt', 'windows-terminal', 'hyper', 'terminator', 'tmux', 'screen'
            )

            Mark-TestCommandsUnavailable -CommandNames $terminalCommands
        }

        It 'Returns empty array when no terminals are available' {
            $result = Get-TerminalInfo

            $result | Should -BeNullOrEmpty
        }

        It 'Returns list of available terminals' {
            Setup-AvailableCommandMock -CommandName 'alacritty'
            Setup-AvailableCommandMock -CommandName 'kitty'
            Setup-AvailableCommandMock -CommandName 'tmux'

            $result = Get-TerminalInfo

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0

            $alacritty = $result | Where-Object { $_.Name -eq 'Alacritty' }
            $alacritty | Should -Not -BeNullOrEmpty
            $alacritty.Command | Should -Be 'alacritty'
            $alacritty.Available | Should -Be $true
        }

        It 'Prefers preferred command variants' {
            Setup-AvailableCommandMock -CommandName 'wezterm-nightly'
            Setup-AvailableCommandMock -CommandName 'wezterm'

            $result = Get-TerminalInfo

            $wezterm = $result | Where-Object { $_.Name -eq 'WezTerm' }
            $wezterm | Should -Not -BeNullOrEmpty
            $wezterm.Command | Should -Be 'wezterm-nightly'
        }
    }
}
