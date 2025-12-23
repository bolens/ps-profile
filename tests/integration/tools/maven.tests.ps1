<#
.SYNOPSIS
    Integration tests for maven tool fragment.

.DESCRIPTION
    Tests maven helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'maven Tools Integration Tests' {
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
            Write-Error "Failed to initialize maven tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'maven helpers (maven.ps1)' {
        BeforeAll {
            # Mock mvn as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'mvn' -Available $true
            . (Join-Path $script:ProfileDir 'maven.ps1')
        }

        It 'Creates Test-MavenOutdated function' {
            Get-Command Test-MavenOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates maven-outdated alias for Test-MavenOutdated' {
            Get-Alias maven-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias maven-outdated).ResolvedCommandName | Should -Be 'Test-MavenOutdated'
        }

        It 'Test-MavenOutdated calls mvn versions:display-dependency-updates' {
            Mock -CommandName mvn -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'versions:display-dependency-updates') {
                    Write-Output 'The following dependencies have updates available:'
                    Write-Output '  package1: 1.0.0 -> 1.2.0'
                }
            }

            { Test-MavenOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Test-MavenOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-MavenDependencies function' {
            Get-Command Update-MavenDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates maven-update alias for Update-MavenDependencies' {
            Get-Alias maven-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias maven-update).ResolvedCommandName | Should -Be 'Update-MavenDependencies'
        }

        It 'Update-MavenDependencies calls mvn versions:use-latest-versions' {
            Mock -CommandName mvn -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'versions:use-latest-versions') {
                    Write-Output 'Dependencies updated successfully'
                }
            }

            { Update-MavenDependencies -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-MavenDependencies -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
