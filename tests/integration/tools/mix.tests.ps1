<#
.SYNOPSIS
    Integration tests for mix tool fragment.

.DESCRIPTION
    Tests mix helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe 'mix Tools Integration Tests' {
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
            Write-Error "Failed to initialize mix tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'mix helpers (mix.ps1)' {
        BeforeAll {
            # Mock mix as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'mix' -Available $true
            . (Join-Path $script:ProfileDir 'mix.ps1')
        }

        It 'Creates Test-MixOutdated function' {
            Get-Command Test-MixOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mix-outdated alias for Test-MixOutdated' {
            Get-Alias mix-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mix-outdated).ResolvedCommandName | Should -Be 'Test-MixOutdated'
        }

        It 'Test-MixOutdated calls mix deps.outdated' {
            Mock -CommandName mix -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'deps.outdated') {
                    Write-Output 'Dependency    Current  Latest'
                    Write-Output 'package1      1.0.0    1.2.0'
                }
            }

            Test-MixOutdated
            Should -Invoke -CommandName 'mix' -Times 1 -Exactly
            Get-Command Test-MixOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-MixDependencies function' {
            Get-Command Update-MixDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mix-update alias for Update-MixDependencies' {
            Get-Alias mix-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mix-update).ResolvedCommandName | Should -Be 'Update-MixDependencies'
        }

        It 'Update-MixDependencies calls mix deps.update --all' {
            Mock -CommandName mix -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'deps.update' -and $args -contains '--all') {
                    Write-Output 'Dependencies updated successfully'
                }
            }

            Update-MixDependencies
            Should -Invoke -CommandName 'mix' -Times 1 -Exactly
            Get-Command Update-MixDependencies -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when mix is unavailable' {
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
                'Test-MixOutdated', 'Update-MixDependencies',
                'Install-MixDependencies', 'Add-MixDependency', 'Remove-MixDependency'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Mock-CommandAvailabilityPester -CommandName 'mix' -Available $false
            $script:MissingMixOutput = & { . (Join-Path $script:ProfileDir 'mix.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when mix is unavailable' {
            Get-Command Test-MixOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when mix is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingMixOutput -Pattern 'mix not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingMixOutput -ToolName 'mix'
        }
    }
}
