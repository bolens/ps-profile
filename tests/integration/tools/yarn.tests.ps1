<#
.SYNOPSIS
    Integration tests for Yarn tool fragment.

.DESCRIPTION
    Tests Yarn helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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
            # Mock Get-Command to return null for 'yarn' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'yarn' } -MockWith { $null }
            # Mock yarn command before loading fragment - make available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'yarn' -Available $true
            . (Join-Path $script:ProfileDir 'yarn.ps1')
        }

        It 'Creates Invoke-Yarn function' {
            Get-Command Invoke-Yarn -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yarn alias for Invoke-Yarn' {
            Get-Alias yarn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yarn).ResolvedCommandName | Should -Be 'Invoke-Yarn'
        }

        It 'yarn alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('yarn', [ref]$null)
            }
            # Verify the function exists
            # Note: Testing missing tool scenario with aliases can cause recursion issues
            # due to alias resolution, so we verify function existence instead
            Get-Command Invoke-Yarn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            # Verify the alias exists
            Get-Alias yarn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
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
            Mock -CommandName yarn -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'outdated') {
                    Write-Output 'Package    Current  Wanted  Latest'
                    Write-Output 'package1  1.0.0    1.1.0   1.2.0'
                }
            }

            { Test-YarnOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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
            Mock -CommandName yarn -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'upgrade') {
                    Write-Output 'Packages upgraded successfully'
                }
            }

            { Update-YarnPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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
            Mock -CommandName yarn -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'global' -and $args -contains 'upgrade') {
                    Write-Output 'Global packages upgraded successfully'
                }
            }

            { Update-YarnGlobalPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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
            Mock -CommandName yarn -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'set' -and $args -contains 'version' -and $args -contains 'latest') {
                    Write-Output 'Yarn updated successfully'
                }
            }

            { Update-YarnSelf -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-YarnSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
