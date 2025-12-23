<#
.SYNOPSIS
    Integration tests for system utility fragments (aliases.ps1).

.DESCRIPTION
    Tests Enable-Aliases helper function.
    These tests verify that functions are created correctly and that
    Enable-Aliases creates the expected aliases and functions.
#>

Describe 'System Utilities - Aliases Integration Tests' {
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
            Write-Error "Failed to initialize system utilities aliases tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Aliases helpers (aliases.ps1)' {
        BeforeAll {
            # Clear the global variable to allow Enable-Aliases to run
            Remove-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'aliases.ps1')
        }

        AfterAll {
            # Clean up after tests
            Remove-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Creates Enable-Aliases function' {
            Get-Command Enable-Aliases -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Enable-Aliases creates Get-ChildItemEnhanced function' {
            Enable-Aliases
            Get-Command Get-ChildItemEnhanced -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Enable-Aliases creates ll alias for Get-ChildItemEnhanced' {
            Enable-Aliases
            Get-Alias ll -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ll).ResolvedCommandName | Should -Be 'Get-ChildItemEnhanced'
        }

        It 'Enable-Aliases creates Get-ChildItemEnhancedAll function' {
            Enable-Aliases
            Get-Command Get-ChildItemEnhancedAll -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Enable-Aliases creates la alias for Get-ChildItemEnhancedAll' {
            Enable-Aliases
            Get-Alias la -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias la).ResolvedCommandName | Should -Be 'Get-ChildItemEnhancedAll'
        }

        It 'Enable-Aliases creates Show-Path function' {
            Enable-Aliases
            Get-Command Show-Path -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Enable-Aliases is idempotent (can be called multiple times)' {
            # Clear the variable to allow re-enabling
            Remove-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction SilentlyContinue
            Enable-Aliases
            $firstCall = $global:AliasesLoaded
            
            # Second call should not change state
            Enable-Aliases
            $secondCall = $global:AliasesLoaded
            
            $firstCall | Should -Be $secondCall
            $firstCall | Should -Be $true
        }
    }
}
