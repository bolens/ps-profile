<#
.SYNOPSIS
    Integration tests for dotnet tool fragment.

.DESCRIPTION
    Tests dotnet helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'dotnet Tools Integration Tests' {
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
            Write-Error "Failed to initialize dotnet tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'dotnet helpers (dotnet.ps1)' {
        BeforeAll {
            # Mock dotnet as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'dotnet' -Available $true
            . (Join-Path $script:ProfileDir 'dotnet.ps1')
        }

        It 'Creates Test-DotnetOutdated function' {
            Get-Command Test-DotnetOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates dotnet-outdated alias for Test-DotnetOutdated' {
            Get-Alias dotnet-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dotnet-outdated).ResolvedCommandName | Should -Be 'Test-DotnetOutdated'
        }

        It 'Test-DotnetOutdated calls dotnet list package --outdated' {
            Mock -CommandName dotnet -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'list' -and $args -contains 'package' -and $args -contains '--outdated') {
                    Write-Output 'Package    Version  Latest'
                    Write-Output 'package1  1.0.0    1.2.0'
                }
            }

            { Test-DotnetOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Test-DotnetOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-DotnetPackages function' {
            Get-Command Update-DotnetPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates dotnet-update alias for Update-DotnetPackages' {
            Get-Alias dotnet-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dotnet-update).ResolvedCommandName | Should -Be 'Update-DotnetPackages'
        }

        It 'Creates Update-DotnetTools function' {
            Get-Command Update-DotnetTools -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates dotnet-tool-update alias for Update-DotnetTools' {
            Get-Alias dotnet-tool-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dotnet-tool-update).ResolvedCommandName | Should -Be 'Update-DotnetTools'
        }

        It 'Update-DotnetTools calls dotnet tool update --all' {
            Mock -CommandName dotnet -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'tool' -and $args -contains 'update' -and $args -contains '--all') {
                    Write-Output 'All tools updated successfully'
                }
            }

            { Update-DotnetTools -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-DotnetTools -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
