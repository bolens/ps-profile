<#
.SYNOPSIS
    Integration tests for julia tool fragment.

.DESCRIPTION
    Tests julia helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe 'julia Tools Integration Tests' {
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
            Write-Error "Failed to initialize julia tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'julia helpers (julia.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'julia' -Available $true
            . (Join-Path $script:ProfileDir 'julia.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Update-JuliaPackages function' {
            Get-Command Update-JuliaPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates julia-update alias for Update-JuliaPackages' {
            Get-Alias julia-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias julia-update).ResolvedCommandName | Should -Be 'Update-JuliaPackages'
        }

        It 'Update-JuliaPackages calls julia -e "using Pkg; Pkg.update()"' {
            Setup-CapturingCommandMock -CommandName 'julia' -Output 'Packages updated successfully'

            Update-JuliaPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-JuliaPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Get-JuliaPackages function' {
            Get-Command Get-JuliaPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates julia-status alias for Get-JuliaPackages' {
            Get-Alias julia-status -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias julia-status).ResolvedCommandName | Should -Be 'Get-JuliaPackages'
        }

        It 'Get-JuliaPackages calls julia -e "using Pkg; Pkg.status()"' {
            Setup-CapturingCommandMock -CommandName 'julia' -Output @(
                'Package    Version'
                'package1  1.0.0'
            )

            Get-JuliaPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Get-JuliaPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when julia is unavailable' {
        BeforeAll {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            @(
                'Update-JuliaPackages', 'Get-JuliaPackages',
                'Add-JuliaPackage', 'Remove-JuliaPackage'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'julia' -Available $false
            $script:MissingJuliaOutput = & { . (Join-Path $script:ProfileDir 'julia.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when julia is unavailable' {
            Get-Command Update-JuliaPackages -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when julia is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingJuliaOutput -Pattern 'julia not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingJuliaOutput -ToolName 'julia'
        }
    }
}
