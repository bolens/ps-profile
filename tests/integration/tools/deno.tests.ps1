<#
.SYNOPSIS
    Integration tests for Deno tool fragment.

.DESCRIPTION
    Tests Deno helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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
}

Describe 'Deno Tools Integration Tests' {
    BeforeAll {
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

    Context 'Deno helpers (deno.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('deno')
            Set-TestCommandAvailabilityState -CommandName 'deno' -Available $true
            . (Join-Path $script:ProfileDir 'deno.ps1')
            Register-TestFragmentAliases @{
                deno          = 'Invoke-Deno'
                'deno-run'    = 'Invoke-DenoRun'
                'deno-task'   = 'Invoke-DenoTask'
                'deno-upgrade' = 'Update-DenoSelf'
            }
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
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
            Setup-CapturingCommandMock -CommandName 'deno' -Output 'Deno updated successfully'

            Update-DenoSelf
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-DenoSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Invoke-Deno emits missing-tool warning when deno is unavailable' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('deno', [ref]$null)
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'deno' -Available $false

            $output = Invoke-Deno --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'deno not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'deno'
        }

        It 'Invoke-DenoRun emits missing-tool warning when deno is unavailable' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('deno', [ref]$null)
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'deno' -Available $false

            $output = Invoke-DenoRun 'main.ts' 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'deno not found'
        }
    }
}
