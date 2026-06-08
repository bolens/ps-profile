<#
.SYNOPSIS
    Integration tests for Yarn tool fragment.

.DESCRIPTION
    Tests Yarn helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe 'Yarn Tools Integration Tests' {
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
            Write-Error "Failed to initialize Yarn tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Yarn helpers (yarn.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('yarn')
            Set-TestCommandAvailabilityState -CommandName 'yarn' -Available $true
            . (Join-Path $script:ProfileDir 'yarn.ps1')
            Register-TestFragmentAliases @{
                yarn                = 'Invoke-Yarn'
                'yarn-add'          = 'Add-YarnPackage'
                'yarn-install'      = 'Install-YarnDependencies'
                'yarn-outdated'     = 'Test-YarnOutdated'
                'yarn-upgrade'      = 'Update-YarnPackages'
                'yarn-global-upgrade' = 'Update-YarnGlobalPackages'
                'yarn-update'       = 'Update-YarnSelf'
            }
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Invoke-Yarn function' {
            Get-Command Invoke-Yarn -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yarn alias for Invoke-Yarn' {
            Get-Alias yarn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yarn).ResolvedCommandName | Should -Be 'Invoke-Yarn'
        }

        It 'Creates Add-YarnPackage function' {
            Get-Command Add-YarnPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yarn-add alias for Add-YarnPackage' {
            Get-Alias yarn-add -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yarn-add).ResolvedCommandName | Should -Be 'Add-YarnPackage'
        }

        It 'Creates Install-YarnDependencies function' {
            Get-Command Install-YarnDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yarn-install alias for Install-YarnDependencies' {
            Get-Alias yarn-install -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yarn-install).ResolvedCommandName | Should -Be 'Install-YarnDependencies'
        }

        It 'Creates Test-YarnOutdated function' {
            Get-Command Test-YarnOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yarn-outdated alias for Test-YarnOutdated' {
            Get-Alias yarn-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yarn-outdated).ResolvedCommandName | Should -Be 'Test-YarnOutdated'
        }

        It 'Test-YarnOutdated calls yarn outdated' {
            Setup-CapturingCommandMock -CommandName 'yarn' -Output @(
                'Package    Current  Wanted  Latest'
                'package1  1.0.0    1.1.0   1.2.0'
            )

            Test-YarnOutdated
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Test-YarnOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-YarnPackages function' {
            Get-Command Update-YarnPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yarn-upgrade alias for Update-YarnPackages' {
            Get-Alias yarn-upgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yarn-upgrade).ResolvedCommandName | Should -Be 'Update-YarnPackages'
        }

        It 'Update-YarnPackages calls yarn upgrade' {
            Setup-CapturingCommandMock -CommandName 'yarn' -Output 'Packages upgraded successfully'

            Update-YarnPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-YarnPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-YarnGlobalPackages function' {
            Get-Command Update-YarnGlobalPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yarn-global-upgrade alias for Update-YarnGlobalPackages' {
            Get-Alias yarn-global-upgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yarn-global-upgrade).ResolvedCommandName | Should -Be 'Update-YarnGlobalPackages'
        }

        It 'Update-YarnGlobalPackages calls yarn global upgrade' {
            Setup-CapturingCommandMock -CommandName 'yarn' -Output 'Global packages upgraded successfully'

            Update-YarnGlobalPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-YarnGlobalPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-YarnSelf function' {
            Get-Command Update-YarnSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yarn-update alias for Update-YarnSelf' {
            Get-Alias yarn-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yarn-update).ResolvedCommandName | Should -Be 'Update-YarnSelf'
        }

        It 'Update-YarnSelf calls yarn set version latest' {
            Setup-CapturingCommandMock -CommandName 'yarn' -Output 'Yarn updated successfully'

            Update-YarnSelf
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-YarnSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Invoke-Yarn emits missing-tool warning when yarn is unavailable' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('yarn', [ref]$null)
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'yarn' -Available $false

            $output = Invoke-Yarn --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'yarn not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'yarn'
        }

        It 'Add-YarnPackage emits missing-tool warning when yarn is unavailable' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('yarn', [ref]$null)
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'yarn' -Available $false

            $output = Add-YarnPackage 'lodash' 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'yarn not found'
        }
    }
}
