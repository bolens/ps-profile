<#
.SYNOPSIS
    Integration tests for gradle tool fragment.

.DESCRIPTION
    Tests gradle helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

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

            Test-GradleOutdated
            Should -Invoke -CommandName 'gradle' -Times 1 -Exactly
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

            Update-GradleWrapper
            Should -Invoke -CommandName 'gradle' -Times 1 -Exactly
            Get-Command Update-GradleWrapper -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when gradle is unavailable' {
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

            @('Test-GradleOutdated', 'Update-GradleWrapper') | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Mock-CommandAvailabilityPester -CommandName 'gradle' -Available $false
            $script:MissingGradleOutput = & { . (Join-Path $script:ProfileDir 'gradle.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when gradle is unavailable' {
            Get-Command Test-GradleOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when gradle is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingGradleOutput -Pattern 'gradle not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingGradleOutput -ToolName 'gradle'
        }
    }
}
