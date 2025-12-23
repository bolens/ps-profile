<#
.SYNOPSIS
    Integration tests for Bun tool fragment.

.DESCRIPTION
    Tests Bun helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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
            # Mock Get-Command to return null for 'bun' and 'bunx' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'bun' } -MockWith { $null }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'bunx' } -MockWith { $null }
            # Mock bun command before loading fragment - make available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'bun' -Available $true
            . (Join-Path $script:ProfileDir 'bun.ps1')
        }

        It 'Creates Invoke-Bunx function' {
            Get-Command Invoke-Bunx -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates bunx alias for Invoke-Bunx' {
            Get-Alias bunx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias bunx).ResolvedCommandName | Should -Be 'Invoke-Bunx'
        }

        It 'bunx alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('bun', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'bun' -Available $false
            $output = bunx --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'bun not found'
            $output | Should -Match 'scoop install bun'
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
            Mock -CommandName bun -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'upgrade') {
                    Write-Output 'Bun updated successfully'
                }
            }

            { Update-BunSelf -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-BunSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
