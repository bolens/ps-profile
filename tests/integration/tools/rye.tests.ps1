<#
.SYNOPSIS
    Integration tests for Rye tool fragment.

.DESCRIPTION
    Tests Rye helper functions.
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

Describe 'Rye Tools Integration Tests' {
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
            Write-Error "Failed to initialize Rye tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Rye helpers (rye.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'rye' -Available $true
            . (Join-Path $script:ProfileDir 'rye.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Add-RyePackage function' {
            Get-Command Add-RyePackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ryeadd alias for Add-RyePackage' {
            Get-Alias ryeadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ryeadd).ResolvedCommandName | Should -Be 'Add-RyePackage'
        }

        It 'Creates ryeinstall alias for Add-RyePackage' {
            Get-Alias ryeinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ryeinstall).ResolvedCommandName | Should -Be 'Add-RyePackage'
        }

        It 'Add-RyePackage calls rye add' {
            Setup-CapturingCommandMock -CommandName 'rye' -Output 'Package added successfully'

            Add-RyePackage -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Add-RyePackage supports --dev flag' {
            Setup-CapturingCommandMock -CommandName 'rye' -Output 'Dev package added successfully'

            Add-RyePackage -Packages pytest -Dev
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Remove-RyePackage function' {
            Get-Command Remove-RyePackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ryeremove alias for Remove-RyePackage' {
            Get-Alias ryeremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ryeremove).ResolvedCommandName | Should -Be 'Remove-RyePackage'
        }

        It 'Creates ryeuninstall alias for Remove-RyePackage' {
            Get-Alias ryeuninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ryeuninstall).ResolvedCommandName | Should -Be 'Remove-RyePackage'
        }

        It 'Remove-RyePackage calls rye remove' {
            Setup-CapturingCommandMock -CommandName 'rye' -Output 'Package removed successfully'

            Remove-RyePackage -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Sync-RyeDependencies function' {
            Get-Command Sync-RyeDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ryesync alias for Sync-RyeDependencies' {
            Get-Alias ryesync -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ryesync).ResolvedCommandName | Should -Be 'Sync-RyeDependencies'
        }

        It 'Sync-RyeDependencies calls rye sync' {
            Setup-CapturingCommandMock -CommandName 'rye' -Output 'Dependencies synced successfully'

            Sync-RyeDependencies
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Update-RyePackages function' {
            Get-Command Update-RyePackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ryeupdate alias for Update-RyePackages' {
            Get-Alias ryeupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ryeupdate).ResolvedCommandName | Should -Be 'Update-RyePackages'
        }

        It 'Update-RyePackages calls rye sync --update-all for all packages' {
            Setup-CapturingCommandMock -CommandName 'rye' -Output 'All packages updated successfully'

            Update-RyePackages
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Update-RyePackages calls rye add --upgrade for specific packages' {
            Setup-CapturingCommandMock -CommandName 'rye' -Output 'requests updated successfully'

            Update-RyePackages -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

    }

    Context 'Graceful degradation when rye is unavailable' {
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

            @('Add-RyePackage', 'Remove-RyePackage', 'Update-RyePackages') | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'rye' -Available $false
            $script:MissingRyeOutput = & { . (Join-Path $script:ProfileDir 'rye.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when rye is unavailable' {
            Get-Command Add-RyePackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when rye is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingRyeOutput -Pattern 'rye not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingRyeOutput -ToolName 'rye'
        }
    }
}
