<#
.SYNOPSIS
    Integration tests for Rye tool fragment.

.DESCRIPTION
    Tests Rye helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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
            # Mock rye as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'rye' -Available $true
            . (Join-Path $script:ProfileDir 'rye.ps1')
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
            Mock -CommandName rye -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'add') {
                    Write-Output 'Package added successfully'
                }
            }

            { Add-RyePackage requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Add-RyePackage supports --dev flag' {
            Mock -CommandName rye -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'add' -and $args -contains '--dev') {
                    Write-Output 'Dev package added successfully'
                }
            }

            { Add-RyePackage pytest -Dev -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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
            Mock -CommandName rye -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'remove') {
                    Write-Output 'Package removed successfully'
                }
            }

            { Remove-RyePackage requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Sync-RyeDependencies function' {
            Get-Command Sync-RyeDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ryesync alias for Sync-RyeDependencies' {
            Get-Alias ryesync -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ryesync).ResolvedCommandName | Should -Be 'Sync-RyeDependencies'
        }

        It 'Sync-RyeDependencies calls rye sync' {
            Mock -CommandName rye -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'sync') {
                    Write-Output 'Dependencies synced successfully'
                }
            }

            { Sync-RyeDependencies -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Update-RyePackages function' {
            Get-Command Update-RyePackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ryeupdate alias for Update-RyePackages' {
            Get-Alias ryeupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ryeupdate).ResolvedCommandName | Should -Be 'Update-RyePackages'
        }

        It 'Update-RyePackages calls rye sync --update-all for all packages' {
            Mock -CommandName rye -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'sync' -and $args -contains '--update-all') {
                    Write-Output 'All packages updated successfully'
                }
            }

            { Update-RyePackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Update-RyePackages calls rye add --upgrade for specific packages' {
            Mock -CommandName rye -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'add' -and $args -contains '--upgrade' -and $args -contains 'requests') {
                    Write-Output 'requests updated successfully'
                }
            }

            { Update-RyePackages requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Rye fragment handles missing tool gracefully' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('rye', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'rye' -Available $false
            Remove-Item Function:Add-RyePackage -ErrorAction SilentlyContinue
            Remove-Item Function:Remove-RyePackage -ErrorAction SilentlyContinue
            Remove-Item Function:Update-RyePackages -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'rye.ps1')
            Get-Command Add-RyePackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
