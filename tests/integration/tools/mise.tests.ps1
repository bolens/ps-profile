<#
.SYNOPSIS
    Integration tests for mise tool fragment.

.DESCRIPTION
    Tests mise helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe 'mise Tools Integration Tests' {
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
            Write-Error "Failed to initialize mise tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'mise helpers (mise.ps1)' {
        BeforeAll {
            # Mock mise as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'mise' -Available $true
            . (Join-Path $script:ProfileDir 'mise.ps1')
        }

        It 'Creates Test-MiseOutdated function' {
            Get-Command Test-MiseOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mise-outdated alias for Test-MiseOutdated' {
            Get-Alias mise-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mise-outdated).ResolvedCommandName | Should -Be 'Test-MiseOutdated'
        }

        It 'Test-MiseOutdated calls mise outdated' {
            Mock -CommandName mise -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'outdated') {
                    Write-Output 'Runtime    Current  Latest'
                    Write-Output 'nodejs     20.0.0   22.0.0'
                }
            }

            Test-MiseOutdated
            Should -Invoke -CommandName 'mise' -Times 1 -Exactly
            Get-Command Test-MiseOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-MiseRuntimes function' {
            Get-Command Update-MiseRuntimes -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mise-update alias for Update-MiseRuntimes' {
            Get-Alias mise-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mise-update).ResolvedCommandName | Should -Be 'Update-MiseRuntimes'
        }

        It 'Update-MiseRuntimes calls mise update' {
            Mock -CommandName mise -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update') {
                    Write-Output 'Runtimes updated successfully'
                }
            }

            Update-MiseRuntimes
            Should -Invoke -CommandName 'mise' -Times 1 -Exactly
            Get-Command Update-MiseRuntimes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-MiseSelf function' {
            Get-Command Update-MiseSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mise-self-update alias for Update-MiseSelf' {
            Get-Alias mise-self-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mise-self-update).ResolvedCommandName | Should -Be 'Update-MiseSelf'
        }

        It 'Update-MiseSelf calls mise self-update' {
            Mock -CommandName mise -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'self-update') {
                    Write-Output 'Mise updated successfully'
                }
            }

            Update-MiseSelf
            Should -Invoke -CommandName 'mise' -Times 1 -Exactly
            Get-Command Update-MiseSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Get-MiseRuntimes function' {
            Get-Command Get-MiseRuntimes -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mise-list alias for Get-MiseRuntimes' {
            Get-Alias mise-list -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mise-list).ResolvedCommandName | Should -Be 'Get-MiseRuntimes'
        }

        It 'Get-MiseRuntimes calls mise list' {
            Mock -CommandName mise -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'list') {
                    Write-Output 'Runtime    Version'
                    Write-Output 'nodejs     20.0.0'
                    Write-Output 'python     3.11.0'
                }
            }

            Get-MiseRuntimes
            Should -Invoke -CommandName 'mise' -Times 1 -Exactly
            Get-Command Get-MiseRuntimes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when mise is unavailable' {
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
                'Test-MiseOutdated', 'Update-MiseRuntimes', 'Update-MiseSelf', 'Get-MiseRuntimes'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Mock-CommandAvailabilityPester -CommandName 'mise' -Available $false
            $script:MissingMiseOutput = & { . (Join-Path $script:ProfileDir 'mise.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when mise is unavailable' {
            Get-Command Test-MiseOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when mise is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingMiseOutput -Pattern 'mise not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingMiseOutput -ToolName 'mise'
        }
    }
}
