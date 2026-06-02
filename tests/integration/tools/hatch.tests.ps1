<#
.SYNOPSIS
    Integration tests for Hatch tool fragment.

.DESCRIPTION
    Tests Hatch helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

Describe 'Hatch Tools Integration Tests' {
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
            Write-Error "Failed to initialize Hatch tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Hatch helpers (hatch.ps1)' {
        BeforeAll {
            # Mock hatch as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'hatch' -Available $true
            . (Join-Path $script:ProfileDir 'hatch.ps1')
        }

        It 'Creates New-HatchEnvironment function' {
            Get-Command New-HatchEnvironment -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates hatchenv alias for New-HatchEnvironment' {
            Get-Alias hatchenv -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias hatchenv).ResolvedCommandName | Should -Be 'New-HatchEnvironment'
        }

        It 'New-HatchEnvironment calls hatch env create' {
            Mock -CommandName hatch -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'env' -and $args -contains 'create') {
                    Write-Output 'Environment created successfully'
                }
            }

            New-HatchEnvironment
            Should -Invoke -CommandName 'hatch' -Times 1 -Exactly
        }

        It 'Creates Build-HatchProject function' {
            Get-Command Build-HatchProject -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates hatchbuild alias for Build-HatchProject' {
            Get-Alias hatchbuild -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias hatchbuild).ResolvedCommandName | Should -Be 'Build-HatchProject'
        }

        It 'Build-HatchProject calls hatch build' {
            Mock -CommandName hatch -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'build') {
                    Write-Output 'Project built successfully'
                }
            }

            Build-HatchProject
            Should -Invoke -CommandName 'hatch' -Times 1 -Exactly
        }

        It 'Creates Get-HatchVersion function' {
            Get-Command Get-HatchVersion -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Set-HatchVersion function' {
            Get-Command Set-HatchVersion -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates hatchversion alias for Get-HatchVersion' {
            Get-Alias hatchversion -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias hatchversion).ResolvedCommandName | Should -Be 'Get-HatchVersion'
        }

        It 'Get-HatchVersion calls hatch version' {
            Mock -CommandName hatch -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'version' -and $args.Count -eq 1) {
                    Write-Output '1.2.3'
                }
            }

            Get-HatchVersion
            Should -Invoke -CommandName 'hatch' -Times 1 -Exactly
        }

        It 'Set-HatchVersion calls hatch version with version' {
            Mock -CommandName hatch -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'version' -and $args -contains '2.0.0') {
                    Write-Output 'Version set to 2.0.0'
                }
            }

            Set-HatchVersion -Version '2.0.0'
            Should -Invoke -CommandName 'hatch' -Times 1 -Exactly
        }

    }

    Context 'Graceful degradation when hatch is unavailable' {
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
                'New-HatchEnvironment', 'Build-HatchProject',
                'Get-HatchVersion', 'Set-HatchVersion'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Mock-CommandAvailabilityPester -CommandName 'hatch' -Available $false
            $script:MissingHatchOutput = & { . (Join-Path $script:ProfileDir 'hatch.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when hatch is unavailable' {
            Get-Command New-HatchEnvironment -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when hatch is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingHatchOutput -Pattern 'hatch not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingHatchOutput -ToolName 'hatch'
        }
    }
}
