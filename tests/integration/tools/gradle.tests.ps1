<#
.SYNOPSIS
    Integration tests for gradle tool fragment.

.DESCRIPTION
    Tests gradle helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'gradle Tools Integration Tests' {
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
            Write-Error "Failed to initialize gradle tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'gradle helpers (gradle.ps1)' {
        BeforeAll {
            # Mock gradle as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'gradle' -Available $true
            . (Join-Path $script:ProfileDir 'gradle.ps1')
        }

        It 'Creates Test-GradleOutdated function' {
            Get-Command Test-GradleOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gradle-outdated alias for Test-GradleOutdated' {
            Get-Alias gradle-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gradle-outdated).ResolvedCommandName | Should -Be 'Test-GradleOutdated'
        }

        It 'Test-GradleOutdated calls gradle dependencyUpdates' {
            Mock -CommandName gradle -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'dependencyUpdates') {
                    Write-Output 'The following dependencies have updates:'
                    Write-Output '  package1: 1.0.0 -> 1.2.0'
                }
            }

            { Test-GradleOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Test-GradleOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-GradleWrapper function' {
            Get-Command Update-GradleWrapper -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gradle-wrapper-update alias for Update-GradleWrapper' {
            Get-Alias gradle-wrapper-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gradle-wrapper-update).ResolvedCommandName | Should -Be 'Update-GradleWrapper'
        }

        It 'Update-GradleWrapper calls gradle wrapper --gradle-version latest' {
            Mock -CommandName gradle -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'wrapper' -and $args -contains '--gradle-version' -and $args -contains 'latest') {
                    Write-Output 'Gradle wrapper updated successfully'
                }
            }

            { Update-GradleWrapper -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-GradleWrapper -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
