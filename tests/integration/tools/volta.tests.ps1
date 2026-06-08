<#
.SYNOPSIS
    Integration tests for Volta tool fragment.

.DESCRIPTION
    Tests Volta helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe 'Volta Tools Integration Tests' {
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
            Write-Error "Failed to initialize Volta tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Volta helpers (volta.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'volta' -Available $true
            . (Join-Path $script:ProfileDir 'volta.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Install-VoltaTool function' {
            Get-Command Install-VoltaTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates voltainstall alias for Install-VoltaTool' {
            Get-Alias voltainstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias voltainstall).ResolvedCommandName | Should -Be 'Install-VoltaTool'
        }

        It 'Creates voltaadd alias for Install-VoltaTool' {
            Get-Alias voltaadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias voltaadd).ResolvedCommandName | Should -Be 'Install-VoltaTool'
        }

        It 'Install-VoltaTool calls volta install' {
            Setup-CapturingCommandMock -CommandName 'volta' -Output 'Tool installed successfully'

            Install-VoltaTool node@18
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Pin-VoltaTool function' {
            Get-Command Pin-VoltaTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates voltapin alias for Pin-VoltaTool' {
            Get-Alias voltapin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias voltapin).ResolvedCommandName | Should -Be 'Pin-VoltaTool'
        }

        It 'Pin-VoltaTool calls volta pin' {
            Setup-CapturingCommandMock -CommandName 'volta' -Output 'Tool pinned successfully'

            Pin-VoltaTool node@18
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Get-VoltaTools function' {
            Get-Command Get-VoltaTools -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates voltalist alias for Get-VoltaTools' {
            Get-Alias voltalist -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias voltalist).ResolvedCommandName | Should -Be 'Get-VoltaTools'
        }

        It 'Get-VoltaTools calls volta list' {
            Setup-CapturingCommandMock -CommandName 'volta' -Output @(
                'node v18.0.0'
                'npm v9.0.0'
            )

            Get-VoltaTools
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Remove-VoltaTool function' {
            Get-Command Remove-VoltaTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates voltauninstall alias for Remove-VoltaTool' {
            Get-Alias voltauninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias voltauninstall).ResolvedCommandName | Should -Be 'Remove-VoltaTool'
        }

        It 'Creates voltaremove alias for Remove-VoltaTool' {
            Get-Alias voltaremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias voltaremove).ResolvedCommandName | Should -Be 'Remove-VoltaTool'
        }

        It 'Remove-VoltaTool calls volta uninstall' {
            Setup-CapturingCommandMock -CommandName 'volta' -Output 'Tool uninstalled successfully'

            Remove-VoltaTool node@18
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Update-VoltaSelf function' {
            Get-Command Update-VoltaSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates voltaselfupdate alias for Update-VoltaSelf' {
            Get-Alias voltaselfupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias voltaselfupdate).ResolvedCommandName | Should -Be 'Update-VoltaSelf'
        }

        It 'Update-VoltaSelf calls volta upgrade' {
            Setup-CapturingCommandMock -CommandName 'volta' -Output 'Volta updated successfully'

            Update-VoltaSelf
            Assert-TestCommandInvokedExactlyOnce
        }

    }
}

Describe 'Volta unavailable graceful degradation' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    }

    It 'Functions are not created when volta is unavailable' {
        $installCommand = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'volta' -Available $false
            . (Join-Path $script:ProfileDir 'volta.ps1')
            Get-Command Install-VoltaTool -ErrorAction SilentlyContinue
        }
        $installCommand | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when volta is unavailable' {
        $output = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'volta' -Available $false
            . (Join-Path $script:ProfileDir 'volta.ps1')
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'volta not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'volta'
    }
}
