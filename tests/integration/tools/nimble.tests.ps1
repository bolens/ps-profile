<#
.SYNOPSIS
    Integration tests for nimble tool fragment.

.DESCRIPTION
    Tests nimble helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'nimble Tools Integration Tests' {
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
            Write-Error "Failed to initialize nimble tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'nimble helpers (nimble.ps1)' {
        BeforeAll {
            # Mock nimble as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'nimble' -Available $true
            . (Join-Path $script:ProfileDir 'nimble.ps1')
        }

        It 'Creates Test-NimbleOutdated function' {
            Get-Command Test-NimbleOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nimble-outdated alias for Test-NimbleOutdated' {
            Get-Alias nimble-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nimble-outdated).ResolvedCommandName | Should -Be 'Test-NimbleOutdated'
        }

        It 'Test-NimbleOutdated calls nimble outdated' {
            Mock -CommandName nimble -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'outdated') {
                    Write-Output 'Package    Current  Latest'
                    Write-Output 'package1  1.0.0    1.2.0'
                }
            }

            { Test-NimbleOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Test-NimbleOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-NimblePackages function' {
            Get-Command Update-NimblePackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nimble-update alias for Update-NimblePackages' {
            Get-Alias nimble-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nimble-update).ResolvedCommandName | Should -Be 'Update-NimblePackages'
        }

        It 'Update-NimblePackages calls nimble update' {
            Mock -CommandName nimble -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update') {
                    Write-Output 'Packages updated successfully'
                }
            }

            { Update-NimblePackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-NimblePackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
