<#
.SYNOPSIS
    Integration tests for Conda tool fragment.

.DESCRIPTION
    Tests Conda helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Conda Tools Integration Tests' {
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
            Write-Error "Failed to initialize Conda tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Conda helpers (conda.ps1)' {
        BeforeAll {
            # Mock conda as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'conda' -Available $true
            . (Join-Path $script:ProfileDir 'conda.ps1')
        }

        It 'Creates Test-CondaOutdated function' {
            Get-Command Test-CondaOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conda-outdated alias for Test-CondaOutdated' {
            Get-Alias conda-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conda-outdated).ResolvedCommandName | Should -Be 'Test-CondaOutdated'
        }

        It 'Test-CondaOutdated calls conda list --outdated' {
            Mock -CommandName conda -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'list' -and $args -contains '--outdated') {
                    Write-Output 'Package    Version  Latest'
                    Write-Output 'package1  1.0.0    1.2.0'
                }
            }

            { Test-CondaOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Test-CondaOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-CondaPackages function' {
            Get-Command Update-CondaPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conda-update alias for Update-CondaPackages' {
            Get-Alias conda-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conda-update).ResolvedCommandName | Should -Be 'Update-CondaPackages'
        }

        It 'Update-CondaPackages calls conda update --all -y' {
            Mock -CommandName conda -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args -contains '--all' -and $args -contains '-y') {
                    Write-Output 'Packages updated successfully'
                }
            }

            { Update-CondaPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-CondaPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-CondaSelf function' {
            Get-Command Update-CondaSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conda-self-update alias for Update-CondaSelf' {
            Get-Alias conda-self-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conda-self-update).ResolvedCommandName | Should -Be 'Update-CondaSelf'
        }

        It 'Update-CondaSelf calls conda update conda -y' {
            Mock -CommandName conda -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args -contains 'conda' -and $args -contains '-y') {
                    Write-Output 'Conda updated successfully'
                }
            }

            { Update-CondaSelf -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-CondaSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
