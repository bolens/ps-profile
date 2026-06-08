<#
.SYNOPSIS
    Integration tests for maven tool fragment.

.DESCRIPTION
    Tests maven helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

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
            Set-TestCommandAvailabilityState -CommandName 'mvn' -Available $true
            . (Join-Path $script:ProfileDir 'maven.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-MavenOutdated function' {
            Get-Command Test-MavenOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates maven-outdated alias for Test-MavenOutdated' {
            Get-Alias maven-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias maven-outdated).ResolvedCommandName | Should -Be 'Test-MavenOutdated'
        }

        It 'Test-MavenOutdated calls mvn versions:display-dependency-updates' {
            Setup-CapturingCommandMock -CommandName 'mvn' -Output @(
                'The following dependencies have updates available:'
                '  package1: 1.0.0 -> 1.2.0'
            )

            Test-MavenOutdated
            Assert-TestCommandInvokedExactlyOnce
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
            Setup-CapturingCommandMock -CommandName 'mvn' -Output 'Dependencies updated successfully'

            Update-MavenDependencies
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-MavenDependencies -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when mvn is unavailable' {
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

            @('Test-MavenOutdated', 'Update-MavenDependencies') | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'mvn' -Available $false
            $script:MissingMavenOutput = & { . (Join-Path $script:ProfileDir 'maven.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when mvn is unavailable' {
            Get-Command Test-MavenOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when mvn is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingMavenOutput -Pattern 'mvn not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingMavenOutput -ToolName 'maven'
        }
    }
}
