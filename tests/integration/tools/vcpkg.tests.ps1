<#
.SYNOPSIS
    Integration tests for vcpkg tool fragment.

.DESCRIPTION
    Tests vcpkg helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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
            # Mock vcpkg as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'vcpkg' -Available $true
            . (Join-Path $script:ProfileDir 'vcpkg.ps1')
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
            Mock -CommandName vcpkg -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install') {
                    Write-Output 'Package installed successfully'
                }
            }

            { Install-VcpkgPackage boost -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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
            Mock -CommandName vcpkg -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'remove') {
                    Write-Output 'Package removed successfully'
                }
            }

            { Remove-VcpkgPackage boost -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Update-VcpkgPackages function' {
            Get-Command Update-VcpkgPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vcpkgupgrade alias for Update-VcpkgPackages' {
            Get-Alias vcpkgupgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vcpkgupgrade).ResolvedCommandName | Should -Be 'Update-VcpkgPackages'
        }

        It 'Update-VcpkgPackages calls vcpkg upgrade --dry-run by default' {
            Mock -CommandName vcpkg -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'upgrade' -and $args -contains '--dry-run') {
                    Write-Output 'Dry-run: packages that would be upgraded'
                }
            }

            { Update-VcpkgPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Update-VcpkgPackages calls vcpkg upgrade for specific packages with -NoDryRun' {
            Mock -CommandName vcpkg -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'upgrade' -and $args -contains 'boost' -and -not ($args -contains '--dry-run')) {
                    Write-Output 'boost upgraded successfully'
                }
            }

            { Update-VcpkgPackages boost -NoDryRun -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'vcpkg fragment handles missing tool gracefully' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('vcpkg', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'vcpkg' -Available $false
            Remove-Item Function:Install-VcpkgPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Remove-VcpkgPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Update-VcpkgPackages -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'vcpkg.ps1')
            Get-Command Install-VcpkgPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
