# ===============================================
# profile-editors-other.tests.ps1
# Unit tests for other editor functions
# ===============================================

function global:Reset-TestEditorCommandAvailability {
    $managedEditorCommands = @(
        'code-insiders', 'code', 'codium', 'cursor', 'neovim-nightly', 'nvim', 'neovim',
        'neovim-qt', 'nvim-qt', 'vim-nightly', 'vim', 'emacs', 'lapce-nightly', 'lapce',
        'zed-nightly', 'zed', 'goneovim-nightly', 'goneovim', 'micro-nightly', 'micro',
        'lighttable', 'theia-ide', 'nano'
    )

    Clear-TestCachedCommandCache | Out-Null

    foreach ($command in $managedEditorCommands) {
        Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue

        if ($global:AssumedAvailableCommands) {
            $removed = $null
            $null = $global:AssumedAvailableCommands.TryRemove($command, [ref]$removed)
        }

        $cacheKey = $command.ToLowerInvariant()
        $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
            Result  = $false
            Expires = (Get-Date).AddHours(24)
        }
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'editors.ps1')

    $script:TestEditorPath = New-TestTempDirectory -Prefix 'EditorPath'
    $script:TestEditorFile = Join-Path $script:TestEditorPath 'script.ps1'
    Set-Content -Path $script:TestEditorFile -Value '# test script'
}

Describe 'editors.ps1 - Other Editor Functions' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestEditorCommandAvailability
        Reset-TestStartProcessMock
    }

    Context 'Edit-WithCursor' {
        It 'Returns null when cursor is not available' {
            $result = Edit-WithCursor -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls cursor when available' {
            Setup-AvailableCommandMock -CommandName 'cursor'

            Edit-WithCursor -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'cursor'
        }

        It 'Calls cursor with new window flag when provided' {
            Setup-AvailableCommandMock -CommandName 'cursor'

            Edit-WithCursor -Path $script:TestEditorPath -NewWindow -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--new-window'
        }

        It 'Handles Start-Process errors gracefully for cursor' {
            Setup-AvailableCommandMock -CommandName 'cursor'
            Set-TestStartProcessFailure -Message 'Process start failed'

            { Edit-WithCursor -Path $script:TestEditorPath -ErrorAction Stop } | Should -Throw '*Process start failed*'
        }
    }

    Context 'Edit-WithNeovim' {
        It 'Returns null when Neovim is not available' {
            $result = Edit-WithNeovim -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls neovim-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'neovim-nightly'

            Edit-WithNeovim -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'neovim-nightly'
        }

        It 'Uses GUI version when UseGui specified' {
            Setup-AvailableCommandMock -CommandName 'neovim-qt'

            Edit-WithNeovim -Path $script:TestEditorPath -UseGui -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'neovim-qt'
        }

        It 'Falls back to nvim when neovim-nightly not available' {
            Setup-AvailableCommandMock -CommandName 'nvim'
            Mark-TestCommandsUnavailable -CommandNames 'neovim-nightly'

            Edit-WithNeovim -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'nvim'
        }

        It 'Handles Start-Process errors gracefully for neovim' {
            Setup-AvailableCommandMock -CommandName 'neovim-nightly'
            Set-TestStartProcessFailure -Message 'Process start failed'

            Edit-WithNeovim -Path $script:TestEditorPath -ErrorAction SilentlyContinue -ErrorVariable neovimErrors | Out-Null

            $neovimErrors | Should -Not -BeNullOrEmpty
            Reset-TestStartProcessMock
        }
    }

    Context 'Launch-Emacs' {
        It 'Returns null when emacs is not available' {
            $result = Launch-Emacs -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls emacs when available' {
            Setup-AvailableCommandMock -CommandName 'emacs'

            Launch-Emacs -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'emacs'
        }

        It 'Calls emacs with daemon flag when NoWindow specified' {
            Setup-AvailableCommandMock -CommandName 'emacs'

            Launch-Emacs -NoWindow -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--daemon'
        }

        It 'Calls emacs with path when provided' {
            Setup-AvailableCommandMock -CommandName 'emacs'

            Launch-Emacs -Path $script:TestEditorFile -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $script:TestEditorFile
        }

        It 'Handles Start-Process errors gracefully for emacs' {
            Setup-AvailableCommandMock -CommandName 'emacs'
            Set-TestStartProcessFailure -Message 'Process start failed'

            Launch-Emacs -ErrorAction SilentlyContinue -ErrorVariable emacsErrors | Out-Null

            $emacsErrors | Should -Not -BeNullOrEmpty
            Reset-TestStartProcessMock
        }
    }

    Context 'Launch-Lapce' {
        It 'Returns null when Lapce is not available' {
            $result = Launch-Lapce -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls lapce-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'lapce-nightly'

            Launch-Lapce -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'lapce-nightly'
        }

        It 'Falls back to lapce when lapce-nightly not available' {
            Setup-AvailableCommandMock -CommandName 'lapce'
            Mark-TestCommandsUnavailable -CommandNames 'lapce-nightly'

            Launch-Lapce -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'lapce'
        }

        It 'Handles Start-Process errors gracefully for lapce' {
            Setup-AvailableCommandMock -CommandName 'lapce-nightly'
            Set-TestStartProcessFailure -Message 'Process start failed'

            Launch-Lapce -Path $script:TestEditorPath -ErrorAction SilentlyContinue -ErrorVariable lapceErrors | Out-Null

            $lapceErrors | Should -Not -BeNullOrEmpty
            Reset-TestStartProcessMock
        }
    }

    Context 'Launch-Zed' {
        It 'Returns null when Zed is not available' {
            $result = Launch-Zed -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls zed-nightly when available' {
            Setup-AvailableCommandMock -CommandName 'zed-nightly'

            Launch-Zed -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'zed-nightly'
        }

        It 'Falls back to zed when zed-nightly not available' {
            Setup-AvailableCommandMock -CommandName 'zed'
            Mark-TestCommandsUnavailable -CommandNames 'zed-nightly'

            Launch-Zed -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'zed'
        }

        It 'Handles Start-Process errors gracefully for zed' {
            Setup-AvailableCommandMock -CommandName 'zed-nightly'
            Set-TestStartProcessFailure -Message 'Process start failed'

            Launch-Zed -Path $script:TestEditorPath -ErrorAction SilentlyContinue -ErrorVariable zedErrors | Out-Null

            $zedErrors | Should -Not -BeNullOrEmpty
            Reset-TestStartProcessMock
        }
    }

    Context 'Get-EditorInfo' {
        It 'Returns empty array when no editors are available' {
            $result = Get-EditorInfo

            @($result).Count | Should -Be 0
        }

        It 'Returns list of available editors' {
            Setup-AvailableCommandMock -CommandName 'code-insiders'
            Setup-AvailableCommandMock -CommandName 'cursor'
            Setup-AvailableCommandMock -CommandName 'neovim-nightly'

            $result = Get-EditorInfo

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0

            $vscode = $result | Where-Object { $_.Name -eq 'VS Code' }
            $vscode | Should -Not -BeNullOrEmpty
            $vscode.Command | Should -Be 'code-insiders'
            $vscode.Available | Should -Be $true
        }

        It 'Prefers preferred command variants' {
            Setup-AvailableCommandMock -CommandName 'lapce-nightly'
            Setup-AvailableCommandMock -CommandName 'lapce'

            $result = Get-EditorInfo

            $lapce = $result | Where-Object { $_.Name -eq 'Lapce' }
            $lapce | Should -Not -BeNullOrEmpty
            $lapce.Command | Should -Be 'lapce-nightly'
        }
    }
}
