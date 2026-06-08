<#
.SYNOPSIS
    Integration tests for nimble tool fragment.

.DESCRIPTION
    Tests nimble helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

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
            Set-TestCommandAvailabilityState -CommandName 'nimble' -Available $true
            . (Join-Path $script:ProfileDir 'nimble.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-NimbleOutdated function' {
            Get-Command Test-NimbleOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nimble-outdated alias for Test-NimbleOutdated' {
            Get-Alias nimble-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nimble-outdated).ResolvedCommandName | Should -Be 'Test-NimbleOutdated'
        }

        It 'Test-NimbleOutdated calls nimble outdated' {
            Setup-CapturingCommandMock -CommandName 'nimble' -Output @(
                'Package    Current  Latest'
                'package1  1.0.0    1.2.0'
            )

            Test-NimbleOutdated
            Assert-TestCommandInvokedExactlyOnce
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
            Setup-CapturingCommandMock -CommandName 'nimble' -Output 'Packages updated successfully'

            Update-NimblePackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-NimblePackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when nimble is unavailable' {
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
                'Test-NimbleOutdated', 'Update-NimblePackages',
                'Install-NimblePackage', 'Remove-NimblePackage'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'nimble' -Available $false
            $script:MissingNimbleOutput = & { . (Join-Path $script:ProfileDir 'nimble.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when nimble is unavailable' {
            Get-Command Test-NimbleOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when nimble is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingNimbleOutput -Pattern 'nim not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingNimbleOutput -ToolName 'nim'
        }
    }
}
