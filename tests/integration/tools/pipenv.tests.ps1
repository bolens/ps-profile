<#
.SYNOPSIS
    Integration tests for Pipenv tool fragment.

.DESCRIPTION
    Tests Pipenv helper functions.
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

Describe 'Pipenv Tools Integration Tests' {
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
            Write-Error "Failed to initialize Pipenv tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Pipenv helpers (pipenv.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'pipenv' -Available $true
            . (Join-Path $script:ProfileDir 'pipenv.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Install-PipenvPackage function' {
            Get-Command Install-PipenvPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipenvinstall alias for Install-PipenvPackage' {
            Get-Alias pipenvinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipenvinstall).ResolvedCommandName | Should -Be 'Install-PipenvPackage'
        }

        It 'Creates pipenvadd alias for Install-PipenvPackage' {
            Get-Alias pipenvadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipenvadd).ResolvedCommandName | Should -Be 'Install-PipenvPackage'
        }

        It 'Install-PipenvPackage calls pipenv install' {
            Setup-CapturingCommandMock -CommandName 'pipenv' -Output 'Package installed successfully'

            Install-PipenvPackage -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Install-PipenvPackage supports --dev flag' {
            Setup-CapturingCommandMock -CommandName 'pipenv' -Output 'Dev package installed successfully'

            Install-PipenvPackage -Packages pytest -Dev
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Remove-PipenvPackage function' {
            Get-Command Remove-PipenvPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipenvuninstall alias for Remove-PipenvPackage' {
            Get-Alias pipenvuninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipenvuninstall).ResolvedCommandName | Should -Be 'Remove-PipenvPackage'
        }

        It 'Creates pipenvremove alias for Remove-PipenvPackage' {
            Get-Alias pipenvremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipenvremove).ResolvedCommandName | Should -Be 'Remove-PipenvPackage'
        }

        It 'Remove-PipenvPackage calls pipenv uninstall' {
            Setup-CapturingCommandMock -CommandName 'pipenv' -Output 'Package removed successfully'

            Remove-PipenvPackage -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Update-PipenvPackages function' {
            Get-Command Update-PipenvPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipenvupdate alias for Update-PipenvPackages' {
            Get-Alias pipenvupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipenvupdate).ResolvedCommandName | Should -Be 'Update-PipenvPackages'
        }

        It 'Update-PipenvPackages calls pipenv update for all packages' {
            Setup-CapturingCommandMock -CommandName 'pipenv' -Output 'All packages updated successfully'

            Update-PipenvPackages
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Update-PipenvPackages calls pipenv update for specific packages' {
            Setup-CapturingCommandMock -CommandName 'pipenv' -Output 'requests updated successfully'

            Update-PipenvPackages -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

    }

    Context 'Graceful degradation when pipenv is unavailable' {
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
                'Install-PipenvPackage', 'Remove-PipenvPackage', 'Update-PipenvPackages'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'pipenv' -Available $false
            $script:MissingPipenvOutput = & { . (Join-Path $script:ProfileDir 'pipenv.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when pipenv is unavailable' {
            Get-Command Install-PipenvPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when pipenv is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingPipenvOutput -Pattern 'pipenv not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingPipenvOutput -ToolName 'pipenv'
        }
    }
}
