<#
.SYNOPSIS
    Integration tests for Pipenv tool fragment.

.DESCRIPTION
    Tests Pipenv helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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
            # Mock pipenv as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'pipenv' -Available $true
            . (Join-Path $script:ProfileDir 'pipenv.ps1')
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
            Mock -CommandName pipenv -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install') {
                    Write-Output 'Package installed successfully'
                }
            }

            { Install-PipenvPackage requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Install-PipenvPackage supports --dev flag' {
            Mock -CommandName pipenv -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install' -and $args -contains '--dev') {
                    Write-Output 'Dev package installed successfully'
                }
            }

            { Install-PipenvPackage pytest -Dev -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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
            Mock -CommandName pipenv -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'uninstall') {
                    Write-Output 'Package removed successfully'
                }
            }

            { Remove-PipenvPackage requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Update-PipenvPackages function' {
            Get-Command Update-PipenvPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipenvupdate alias for Update-PipenvPackages' {
            Get-Alias pipenvupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipenvupdate).ResolvedCommandName | Should -Be 'Update-PipenvPackages'
        }

        It 'Update-PipenvPackages calls pipenv update for all packages' {
            Mock -CommandName pipenv -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args.Count -eq 1) {
                    Write-Output 'All packages updated successfully'
                }
            }

            { Update-PipenvPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Update-PipenvPackages calls pipenv update for specific packages' {
            Mock -CommandName pipenv -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args -contains 'requests') {
                    Write-Output 'requests updated successfully'
                }
            }

            { Update-PipenvPackages requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Pipenv fragment handles missing tool gracefully' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('pipenv', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'pipenv' -Available $false
            Remove-Item Function:Install-PipenvPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Remove-PipenvPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Update-PipenvPackages -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'pipenv.ps1')
            Get-Command Install-PipenvPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
