<#
.SYNOPSIS
    Integration tests for system utility fragments (clipboard.ps1).

.DESCRIPTION
    Tests clipboard helper functions (Copy-ToClipboard, Get-FromClipboard).
    These tests verify that functions are created correctly and aliases are set up properly.
#>

Describe 'System Utilities - Clipboard Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize system utilities clipboard tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Clipboard helpers (clipboard.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'clipboard.ps1')
        }

        It 'Creates Copy-ToClipboard function' {
            Get-Command Copy-ToClipboard -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates cb alias for Copy-ToClipboard' {
            Get-Alias cb -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias cb).ResolvedCommandName | Should -Be 'Copy-ToClipboard'
        }

        It 'Creates Get-FromClipboard function' {
            Get-Command Get-FromClipboard -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pb alias for Get-FromClipboard' {
            Get-Alias pb -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pb).ResolvedCommandName | Should -Be 'Get-FromClipboard'
        }

        It 'Copy-ToClipboard function accepts pipeline input' {
            # Test that the function accepts pipeline input (it has ValueFromPipeline parameter)
            $testText = "Test clipboard content $(Get-Random)"
            try {
                $testText | Copy-ToClipboard
                $result = $true
            }
            catch {
                $result = $false
            }
            $result | Should -Be $true
        }
    }
}

