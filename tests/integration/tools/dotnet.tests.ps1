<#
.SYNOPSIS
    Integration tests for dotnet tool fragment.

.DESCRIPTION
    Tests dotnet helper functions.
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
            Set-TestCommandAvailabilityState -CommandName 'dotnet' -Available $true
            . (Join-Path $script:ProfileDir 'dotnet.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-DotnetOutdated function' {
            Get-Command Test-DotnetOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates dotnet-outdated alias for Test-DotnetOutdated' {
            Get-Alias dotnet-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dotnet-outdated).ResolvedCommandName | Should -Be 'Test-DotnetOutdated'
        }

        It 'Test-DotnetOutdated calls dotnet list package --outdated' {
            Setup-CapturingCommandMock -CommandName 'dotnet' -Output @(
                'Package    Version  Latest'
                'package1  1.0.0    1.2.0'
            )

            Test-DotnetOutdated
            Assert-TestCommandInvokedExactlyOnce
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
            Setup-CapturingCommandMock -CommandName 'dotnet' -Output 'All tools updated successfully'

            Update-DotnetTools
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-DotnetTools -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when dotnet is unavailable' {
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
                'Test-DotnetOutdated', 'Update-DotnetPackages', 'Update-DotnetTools',
                'Restore-DotnetPackages', 'Add-DotnetPackage', 'Remove-DotnetPackage'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'dotnet' -Available $false
            $script:MissingDotnetOutput = & { . (Join-Path $script:ProfileDir 'dotnet.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when dotnet is unavailable' {
            Get-Command Test-DotnetOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when dotnet is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingDotnetOutput -Pattern 'dotnet not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingDotnetOutput -ToolName 'dotnet'
        }
    }
}
