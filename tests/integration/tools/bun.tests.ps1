<#
.SYNOPSIS
    Integration tests for Bun tool fragment.

.DESCRIPTION
    Tests Bun helper functions.
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

Describe 'Bun Tools Integration Tests' {
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
            Write-Error "Failed to initialize Bun tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Bun helpers (bun.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('bun', 'bunx')
            Set-TestCommandAvailabilityState -CommandName 'bun' -Available $true
            . (Join-Path $script:ProfileDir 'bun.ps1')
            Register-TestFragmentAliases @{
                bunx        = 'Invoke-Bunx'
                'bun-run'   = 'Invoke-BunRun'
                'bun-add'   = 'Add-BunPackage'
                'bun-upgrade' = 'Update-BunSelf'
            }
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Invoke-Bunx function' {
            Get-Command Invoke-Bunx -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates bunx alias for Invoke-Bunx' {
            Get-Alias bunx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias bunx).ResolvedCommandName | Should -Be 'Invoke-Bunx'
        }

        It 'Creates Invoke-BunRun function' {
            Get-Command Invoke-BunRun -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates bun-run alias for Invoke-BunRun' {
            Get-Alias bun-run -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias bun-run).ResolvedCommandName | Should -Be 'Invoke-BunRun'
        }

        It 'Creates Add-BunPackage function' {
            Get-Command Add-BunPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates bun-add alias for Add-BunPackage' {
            Get-Alias bun-add -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias bun-add).ResolvedCommandName | Should -Be 'Add-BunPackage'
        }

        It 'Creates Update-BunSelf function' {
            Get-Command Update-BunSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates bun-upgrade alias for Update-BunSelf' {
            Get-Alias bun-upgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias bun-upgrade).ResolvedCommandName | Should -Be 'Update-BunSelf'
        }

        It 'Update-BunSelf calls bun upgrade' {
            Set-TestCommandAvailabilityState -CommandName 'bun' -Available $true
            Setup-CapturingCommandMock -CommandName 'bun' -Output 'Bun updated successfully'
            Update-BunSelf

            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'upgrade'
        }
    }

    Context 'Graceful degradation when bun is unavailable' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('bun', 'bunx')
            Set-TestCommandAvailabilityState -CommandName 'bun' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'bunx' -Available $false
            . (Join-Path $script:ProfileDir 'bun.ps1')
        }

        It 'bunx alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('bun', [ref]$null)
            }
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }

            Mark-TestCommandsUnavailable -CommandNames @('bun', 'bunx')
            Set-TestCommandAvailabilityState -CommandName 'bun' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'bunx' -Available $false
            Set-Alias -Name bunx -Value Invoke-Bunx -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null

            $output = bunx --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'bun not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'bun'
        }
    }
}
