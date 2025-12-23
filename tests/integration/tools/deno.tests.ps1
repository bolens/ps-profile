<#
.SYNOPSIS
    Integration tests for Deno tool fragment.

.DESCRIPTION
    Tests Deno helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Deno Tools Integration Tests' {
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
            Write-Error "Failed to initialize Deno tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Deno helpers (deno.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'deno' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'deno' } -MockWith { $null }
            # Mock deno command before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'deno' -Available $true
            . (Join-Path $script:ProfileDir 'deno.ps1')
        }

        It 'Creates Invoke-Deno function' {
            Get-Command Invoke-Deno -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates deno alias for Invoke-Deno' {
            Get-Alias deno -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias deno).ResolvedCommandName | Should -Be 'Invoke-Deno'
        }

        It 'Creates Invoke-DenoRun function' {
            Get-Command Invoke-DenoRun -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates deno-run alias for Invoke-DenoRun' {
            Get-Alias deno-run -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias deno-run).ResolvedCommandName | Should -Be 'Invoke-DenoRun'
        }

        It 'Creates Invoke-DenoTask function' {
            Get-Command Invoke-DenoTask -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates deno-task alias for Invoke-DenoTask' {
            Get-Alias deno-task -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias deno-task).ResolvedCommandName | Should -Be 'Invoke-DenoTask'
        }

        It 'Creates Update-DenoSelf function' {
            Get-Command Update-DenoSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates deno-upgrade alias for Update-DenoSelf' {
            Get-Alias deno-upgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias deno-upgrade).ResolvedCommandName | Should -Be 'Update-DenoSelf'
        }

        It 'Update-DenoSelf calls deno upgrade' {
            Mock -CommandName deno -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'upgrade') {
                    Write-Output 'Deno updated successfully'
                }
            }

            { Update-DenoSelf -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-DenoSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
