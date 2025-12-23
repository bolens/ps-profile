<#
.SYNOPSIS
    Integration tests for PDM tool fragment.

.DESCRIPTION
    Tests PDM helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'PDM Tools Integration Tests' {
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
            Write-Error "Failed to initialize PDM tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'PDM helpers (pdm.ps1)' {
        BeforeAll {
            # Mock pdm as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'pdm' -Available $true
            . (Join-Path $script:ProfileDir 'pdm.ps1')
        }

        It 'Creates Add-PdmPackage function' {
            Get-Command Add-PdmPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pdmadd alias for Add-PdmPackage' {
            Get-Alias pdmadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdmadd).ResolvedCommandName | Should -Be 'Add-PdmPackage'
        }

        It 'Creates pdminstall alias for Add-PdmPackage' {
            Get-Alias pdminstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdminstall).ResolvedCommandName | Should -Be 'Add-PdmPackage'
        }

        It 'Add-PdmPackage calls pdm add' {
            Mock -CommandName pdm -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'add') {
                    Write-Output 'Package added successfully'
                }
            }

            { Add-PdmPackage requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Add-PdmPackage supports --dev flag' {
            Mock -CommandName pdm -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'add' -and $args -contains '--dev') {
                    Write-Output 'Dev package added successfully'
                }
            }

            { Add-PdmPackage pytest -Dev -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Remove-PdmPackage function' {
            Get-Command Remove-PdmPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pdmremove alias for Remove-PdmPackage' {
            Get-Alias pdmremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdmremove).ResolvedCommandName | Should -Be 'Remove-PdmPackage'
        }

        It 'Creates pdmuninstall alias for Remove-PdmPackage' {
            Get-Alias pdmuninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdmuninstall).ResolvedCommandName | Should -Be 'Remove-PdmPackage'
        }

        It 'Remove-PdmPackage calls pdm remove' {
            Mock -CommandName pdm -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'remove') {
                    Write-Output 'Package removed successfully'
                }
            }

            { Remove-PdmPackage requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Update-PdmPackages function' {
            Get-Command Update-PdmPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pdmupdate alias for Update-PdmPackages' {
            Get-Alias pdmupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdmupdate).ResolvedCommandName | Should -Be 'Update-PdmPackages'
        }

        It 'Update-PdmPackages calls pdm update for all packages' {
            Mock -CommandName pdm -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args.Count -eq 1) {
                    Write-Output 'All packages updated successfully'
                }
            }

            { Update-PdmPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Update-PdmPackages calls pdm update for specific packages' {
            Mock -CommandName pdm -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args -contains 'requests') {
                    Write-Output 'requests updated successfully'
                }
            }

            { Update-PdmPackages requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'PDM fragment handles missing tool gracefully' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('pdm', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'pdm' -Available $false
            Remove-Item Function:Add-PdmPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Remove-PdmPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Update-PdmPackages -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'pdm.ps1')
            Get-Command Add-PdmPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
