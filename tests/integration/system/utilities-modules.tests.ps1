<#
.SYNOPSIS
    Integration tests for system utility fragments (modules.ps1).

.DESCRIPTION
    Tests lazy-loading module helper functions (Enable-PoshGit, Enable-PSReadLine).
    These tests verify that functions are created correctly and are idempotent.
#>

Describe 'System Utilities - Modules Integration Tests' {
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
            Write-Error "Failed to initialize system utilities modules tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Module helpers (modules.ps1)' {
        BeforeAll {
            # Clear the guard variable to allow loading
            Remove-Variable -Name 'ModulesLoaded' -Scope Global -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'modules.ps1')
        }

        AfterAll {
            # Clean up after tests
            Remove-Variable -Name 'ModulesLoaded' -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Creates Enable-PoshGit function' {
            Get-Command Enable-PoshGit -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Enable-PSReadLine function' {
            Get-Command Enable-PSReadLine -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Enable-PoshGit function can be called (module may not be installed)' {
            # Function should exist and be callable, even if module isn't installed
            { Enable-PoshGit } | Should -Not -Throw
        }

        It 'Enable-PSReadLine function can be called (module may not be installed)' {
            # Function should exist and be callable, even if module isn't installed
            { Enable-PSReadLine } | Should -Not -Throw
        }

        It 'Fragment is idempotent (can be loaded multiple times)' {
            # Clear the variable to allow re-loading
            Remove-Variable -Name 'ModulesLoaded' -Scope Global -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'modules.ps1')
            $firstLoad = $global:ModulesLoaded
            
            # Second load should not change state
            . (Join-Path $script:ProfileDir 'modules.ps1')
            $secondLoad = $global:ModulesLoaded
            
            $firstLoad | Should -Be $secondLoad
            $firstLoad | Should -Be $true
            
            # Functions should still exist
            Get-Command Enable-PoshGit -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Enable-PSReadLine -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

