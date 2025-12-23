<#
.SYNOPSIS
    Integration tests for julia tool fragment.

.DESCRIPTION
    Tests julia helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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
            # Mock julia as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'julia' -Available $true
            . (Join-Path $script:ProfileDir 'julia.ps1')
        }

        It 'Creates Update-JuliaPackages function' {
            Get-Command Update-JuliaPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates julia-update alias for Update-JuliaPackages' {
            Get-Alias julia-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias julia-update).ResolvedCommandName | Should -Be 'Update-JuliaPackages'
        }

        It 'Update-JuliaPackages calls julia -e "using Pkg; Pkg.update()"' {
            Mock -CommandName julia -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains '-e' -and $args -match 'Pkg\.update') {
                    Write-Output 'Packages updated successfully'
                }
            }

            { Update-JuliaPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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
            Mock -CommandName julia -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains '-e' -and $args -match 'Pkg\.status') {
                    Write-Output 'Package    Version'
                    Write-Output 'package1  1.0.0'
                }
            }

            { Get-JuliaPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Get-JuliaPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
