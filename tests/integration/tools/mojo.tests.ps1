<#
.SYNOPSIS
    Integration tests for Mojo tool fragment.

.DESCRIPTION
    Tests Mojo helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

Describe 'Mojo Tools Integration Tests' {
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
            Write-Error "Failed to initialize Mojo tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Mojo helpers (mojo.ps1)' {
        BeforeAll {
            # Mock mojo as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'mojo' -Available $true
            . (Join-Path $script:ProfileDir 'mojo.ps1')
        }

        It 'Creates Invoke-MojoRun function' {
            Get-Command Invoke-MojoRun -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mojo-run alias for Invoke-MojoRun' {
            Get-Alias mojo-run -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mojo-run).ResolvedCommandName | Should -Be 'Invoke-MojoRun'
        }

        It 'Creates Build-MojoProgram function' {
            Get-Command Build-MojoProgram -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mojo-build alias for Build-MojoProgram' {
            Get-Alias mojo-build -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mojo-build).ResolvedCommandName | Should -Be 'Build-MojoProgram'
        }

        It 'Creates Update-MojoSelf function' {
            Get-Command Update-MojoSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mojo-update alias for Update-MojoSelf' {
            Get-Alias mojo-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mojo-update).ResolvedCommandName | Should -Be 'Update-MojoSelf'
        }

        It 'Update-MojoSelf calls mojo update' {
            Mock -CommandName mojo -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update') {
                    Write-Output 'Mojo updated successfully'
                }
            }

            Update-MojoSelf
            Should -Invoke -CommandName 'mojo' -Times 1 -Exactly
            Get-Command Update-MojoSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when mojo is unavailable' {
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

            @('Invoke-MojoRun', 'Build-MojoProgram', 'Update-MojoSelf') | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Mock-CommandAvailabilityPester -CommandName 'mojo' -Available $false
            $script:MissingMojoOutput = & { . (Join-Path $script:ProfileDir 'mojo.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when mojo is unavailable' {
            Get-Command Invoke-MojoRun -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when mojo is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingMojoOutput -Pattern 'mojo not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingMojoOutput -ToolName 'mojo'
        }
    }
}
