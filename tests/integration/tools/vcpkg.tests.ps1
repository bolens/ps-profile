<#
.SYNOPSIS
    Integration tests for vcpkg tool fragment.

.DESCRIPTION
    Tests vcpkg helper functions.
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

Describe 'vcpkg Tools Integration Tests' {
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
            Write-Error "Failed to initialize vcpkg tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'vcpkg helpers (vcpkg.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'vcpkg' -Available $true
            . (Join-Path $script:ProfileDir 'vcpkg.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Install-VcpkgPackage function' {
            Get-Command Install-VcpkgPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vcpkginstall alias for Install-VcpkgPackage' {
            Get-Alias vcpkginstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vcpkginstall).ResolvedCommandName | Should -Be 'Install-VcpkgPackage'
        }

        It 'Creates vcpkgadd alias for Install-VcpkgPackage' {
            Get-Alias vcpkgadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vcpkgadd).ResolvedCommandName | Should -Be 'Install-VcpkgPackage'
        }

        It 'Install-VcpkgPackage calls vcpkg install' {
            Setup-CapturingCommandMock -CommandName 'vcpkg' -Output 'Package installed successfully'

            Install-VcpkgPackage -Packages boost
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Remove-VcpkgPackage function' {
            Get-Command Remove-VcpkgPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vcpkgremove alias for Remove-VcpkgPackage' {
            Get-Alias vcpkgremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vcpkgremove).ResolvedCommandName | Should -Be 'Remove-VcpkgPackage'
        }

        It 'Creates vcpkguninstall alias for Remove-VcpkgPackage' {
            Get-Alias vcpkguninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vcpkguninstall).ResolvedCommandName | Should -Be 'Remove-VcpkgPackage'
        }

        It 'Remove-VcpkgPackage calls vcpkg remove' {
            Setup-CapturingCommandMock -CommandName 'vcpkg' -Output 'Package removed successfully'

            Remove-VcpkgPackage -Packages boost
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Update-VcpkgPackages function' {
            Get-Command Update-VcpkgPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vcpkgupgrade alias for Update-VcpkgPackages' {
            Get-Alias vcpkgupgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vcpkgupgrade).ResolvedCommandName | Should -Be 'Update-VcpkgPackages'
        }

        It 'Update-VcpkgPackages calls vcpkg upgrade --dry-run by default' {
            Setup-CapturingCommandMock -CommandName 'vcpkg' -Output 'Dry-run: packages that would be upgraded'

            Update-VcpkgPackages
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Update-VcpkgPackages calls vcpkg upgrade for specific packages with -NoDryRun' {
            Setup-CapturingCommandMock -CommandName 'vcpkg' -Output 'boost upgraded successfully'

            Update-VcpkgPackages -Packages boost -NoDryRun
            Assert-TestCommandInvokedExactlyOnce
        }

    }
}

Describe 'vcpkg unavailable graceful degradation' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    }

    It 'Functions are not created when vcpkg is unavailable' {
        $installCommand = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            @('Install-VcpkgPackage', 'Remove-VcpkgPackage', 'Update-VcpkgPackages') | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }
            Set-TestCommandAvailabilityState -CommandName 'vcpkg' -Available $false
            . (Join-Path $script:ProfileDir 'vcpkg.ps1')
            Get-Command Install-VcpkgPackage -ErrorAction SilentlyContinue
        }
        $installCommand | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when vcpkg is unavailable' {
        $output = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'vcpkg' -Available $false
            . (Join-Path $script:ProfileDir 'vcpkg.ps1')
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'vcpkg not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'vcpkg'
    }
}
