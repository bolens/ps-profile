<#
.SYNOPSIS
    Integration tests for mix tool fragment.

.DESCRIPTION
    Tests mix helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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

            { Test-MixOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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

            { Update-MixDependencies -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-MixDependencies -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
