# ===============================================
# profile-editors-vscode.tests.ps1
# Unit tests for VS Code editor functions
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
    . (Join-Path $script:ProfileDir 'editors.ps1')

    $script:TestEditorPath = New-TestTempDirectory -Prefix 'VSCodeEditorPath'
}

Describe 'editors.ps1 - VS Code Functions' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestEditorCommandAvailability
        Reset-TestStartProcessMock
    }

    Context 'Edit-WithVSCode' {
        It 'Returns null when VS Code is not available' {
            $result = Edit-WithVSCode -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls code-insiders when available' {
            Set-TestCommandAvailabilityState -CommandName 'code-insiders'

            Edit-WithVSCode -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'code-insiders'
        }

        It 'Falls back to code when code-insiders not available' {
            Set-TestCommandAvailabilityState -CommandName 'code'
            Mark-TestCommandsUnavailable -CommandNames 'code-insiders'

            Edit-WithVSCode -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'code'
        }

        It 'Falls back to codium when code-insiders and code not available' {
            Set-TestCommandAvailabilityState -CommandName 'codium'
            Mark-TestCommandsUnavailable -CommandNames @('code-insiders', 'code')

            Edit-WithVSCode -Path $script:TestEditorPath -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'codium'
        }

        It 'Calls VS Code with new window flag when provided' {
            Set-TestCommandAvailabilityState -CommandName 'code-insiders'

            Edit-WithVSCode -Path $script:TestEditorPath -NewWindow -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--new-window'
        }

        It 'Calls VS Code with wait flag when provided' {
            Set-TestCommandAvailabilityState -CommandName 'code-insiders'

            Edit-WithVSCode -Path $script:TestEditorPath -Wait -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--wait'
            $capture.Wait | Should -Be $true
            $capture.PassThru | Should -Be $true
        }

        It 'Handles VS Code exit code when Wait is used' {
            Set-TestCommandAvailabilityState -CommandName 'code-insiders'

            Edit-WithVSCode -Path $script:TestEditorPath -Wait -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--wait'
        }

        It 'Handles Start-Process errors gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'code-insiders'
            Set-TestStartProcessFailure -Message 'Process start failed'

            { Edit-WithVSCode -Path $script:TestEditorPath -ErrorAction Stop } | Should -Throw '*Process start failed*'
        }

        It 'Returns null when path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'code-insiders'
            $missingPath = Join-Path (New-TestTempDirectory -Prefix 'VSCodeMissingPath') 'nonexistent'

            $result = Edit-WithVSCode -Path $missingPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }
    }
}
