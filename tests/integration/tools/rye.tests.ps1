<#
.SYNOPSIS
    Integration tests for Rye tool fragment.

.DESCRIPTION
    Tests Rye helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

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

            Add-RyePackage requests
            Should -Invoke -CommandName 'rye' -Times 1 -Exactly
        }

        It 'Add-RyePackage supports --dev flag' {
            Mock -CommandName rye -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'add' -and $args -contains '--dev') {
                    Write-Output 'Dev package added successfully'
                }
            }

            Add-RyePackage pytest -Dev
            Should -Invoke -CommandName 'rye' -Times 1 -Exactly
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

            Remove-RyePackage requests
            Should -Invoke -CommandName 'rye' -Times 1 -Exactly
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

            Sync-RyeDependencies
            Should -Invoke -CommandName 'rye' -Times 1 -Exactly
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

            Update-RyePackages
            Should -Invoke -CommandName 'rye' -Times 1 -Exactly
        }

        It 'Update-RyePackages calls rye add --upgrade for specific packages' {
            Mock -CommandName rye -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'add' -and $args -contains '--upgrade' -and $args -contains 'requests') {
                    Write-Output 'requests updated successfully'
                }
            }

            Update-RyePackages requests
            Should -Invoke -CommandName 'rye' -Times 1 -Exactly
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

            Mock-CommandAvailabilityPester -CommandName 'rye' -Available $false
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
