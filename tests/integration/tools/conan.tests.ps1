<#
.SYNOPSIS
    Integration tests for Conan tool fragment.

.DESCRIPTION
    Tests Conan helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Conan Tools Integration Tests' {
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
            Write-Error "Failed to initialize Conan tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Conan helpers (conan.ps1)' {
        BeforeAll {
            # Mock conan as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'conan' -Available $true
            . (Join-Path $script:ProfileDir 'conan.ps1')
        }

        It 'Creates Install-ConanPackages function' {
            Get-Command Install-ConanPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conaninstall alias for Install-ConanPackages' {
            Get-Alias conaninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conaninstall).ResolvedCommandName | Should -Be 'Install-ConanPackages'
        }

        It 'Install-ConanPackages calls conan install' {
            Mock -CommandName conan -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install') {
                    Write-Output 'Packages installed successfully'
                }
            }

            { Install-ConanPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates New-ConanPackage function' {
            Get-Command New-ConanPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conancreate alias for New-ConanPackage' {
            Get-Alias conancreate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conancreate).ResolvedCommandName | Should -Be 'New-ConanPackage'
        }

        It 'New-ConanPackage calls conan create' {
            Mock -CommandName conan -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'create') {
                    Write-Output 'Package created successfully'
                }
            }

            { New-ConanPackage ./conanfile.py -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Find-ConanPackage function' {
            Get-Command Find-ConanPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conansearch alias for Find-ConanPackage' {
            Get-Alias conansearch -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conansearch).ResolvedCommandName | Should -Be 'Find-ConanPackage'
        }

        It 'Find-ConanPackage calls conan search' {
            Mock -CommandName conan -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'search' -and $args -contains 'boost') {
                    Write-Output 'boost/1.82.0'
                }
            }

            { Find-ConanPackage boost -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Update-ConanPackages function' {
            Get-Command Update-ConanPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conanupdate alias for Update-ConanPackages' {
            Get-Alias conanupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conanupdate).ResolvedCommandName | Should -Be 'Update-ConanPackages'
        }

        It 'Update-ConanPackages calls conan install --update' {
            Mock -CommandName conan -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install' -and $args -contains '--update') {
                    Write-Output 'Packages updated successfully'
                }
            }

            { Update-ConanPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Conan fragment handles missing tool gracefully' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('conan', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'conan' -Available $false
            Remove-Item Function:Install-ConanPackages -ErrorAction SilentlyContinue
            Remove-Item Function:Update-ConanPackages -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'conan.ps1')
            Get-Command Install-ConanPackages -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
