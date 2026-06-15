<#
.SYNOPSIS
    Integration tests for Conda tool fragment.

.DESCRIPTION
    Tests Conda helper functions.
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

Describe 'Conda Tools Integration Tests' {
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
            Write-Error "Failed to initialize Conda tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Conda helpers (conda.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'conda' -Available $true
            . (Join-Path $script:ProfileDir 'conda.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-CondaOutdated function' {
            Get-Command Test-CondaOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conda-outdated alias for Test-CondaOutdated' {
            Get-Alias conda-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conda-outdated).ResolvedCommandName | Should -Be 'Test-CondaOutdated'
        }

        It 'Test-CondaOutdated calls conda list --outdated' {
            Setup-CapturingCommandMock -CommandName 'conda' -Output @(
                'Package    Version  Latest'
                'package1  1.0.0    1.2.0'
            )

            Test-CondaOutdated
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Test-CondaOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-CondaPackages function' {
            Get-Command Update-CondaPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conda-update alias for Update-CondaPackages' {
            Get-Alias conda-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conda-update).ResolvedCommandName | Should -Be 'Update-CondaPackages'
        }

        It 'Update-CondaPackages calls conda update --all -y' {
            Setup-CapturingCommandMock -CommandName 'conda' -Output 'Packages updated successfully'

            Update-CondaPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-CondaPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-CondaSelf function' {
            Get-Command Update-CondaSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conda-self-update alias for Update-CondaSelf' {
            Get-Alias conda-self-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conda-self-update).ResolvedCommandName | Should -Be 'Update-CondaSelf'
        }

        It 'Update-CondaSelf calls conda update conda -y' {
            Setup-CapturingCommandMock -CommandName 'conda' -Output 'Conda updated successfully'

            Update-CondaSelf
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-CondaSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when conda is unavailable' {
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
                'Test-CondaOutdated', 'Update-CondaPackages', 'Update-CondaSelf'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'conda' -Available $false
            $script:MissingCondaOutput = & { . (Join-Path $script:ProfileDir 'conda.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when conda is unavailable' {
            Get-Command Test-CondaOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when conda is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingCondaOutput -Pattern 'conda not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingCondaOutput -ToolName 'conda'
        }
    }
}
