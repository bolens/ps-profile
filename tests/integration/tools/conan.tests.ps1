<#
.SYNOPSIS
    Integration tests for Conan tool fragment.

.DESCRIPTION
    Tests Conan helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

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
            Set-TestCommandAvailabilityState -CommandName 'conan' -Available $true
            . (Join-Path $script:ProfileDir 'conan.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Install-ConanPackages function' {
            Get-Command Install-ConanPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conaninstall alias for Install-ConanPackages' {
            Get-Alias conaninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conaninstall).ResolvedCommandName | Should -Be 'Install-ConanPackages'
        }

        It 'Install-ConanPackages calls conan install' {
            Setup-CapturingCommandMock -CommandName 'conan' -Output 'Packages installed successfully'

            Install-ConanPackages
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates New-ConanPackage function' {
            Get-Command New-ConanPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conancreate alias for New-ConanPackage' {
            Get-Alias conancreate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conancreate).ResolvedCommandName | Should -Be 'New-ConanPackage'
        }

        It 'New-ConanPackage calls conan create' {
            Setup-CapturingCommandMock -CommandName 'conan' -Output 'Package created successfully'

            New-ConanPackage ./conanfile.py
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Find-ConanPackage function' {
            Get-Command Find-ConanPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conansearch alias for Find-ConanPackage' {
            Get-Alias conansearch -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conansearch).ResolvedCommandName | Should -Be 'Find-ConanPackage'
        }

        It 'Find-ConanPackage calls conan search' {
            Setup-CapturingCommandMock -CommandName 'conan' -Output 'boost/1.82.0'

            Find-ConanPackage boost
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Update-ConanPackages function' {
            Get-Command Update-ConanPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates conanupdate alias for Update-ConanPackages' {
            Get-Alias conanupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias conanupdate).ResolvedCommandName | Should -Be 'Update-ConanPackages'
        }

        It 'Update-ConanPackages calls conan install --update' {
            Setup-CapturingCommandMock -CommandName 'conan' -Output 'Packages updated successfully'

            Update-ConanPackages
            Assert-TestCommandInvokedExactlyOnce
        }

    }
}

Describe 'Conan unavailable graceful degradation' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    }

    It 'Functions are not created when conan is unavailable' {
        $installCommand = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'conan' -Available $false
            . (Join-Path $script:ProfileDir 'conan.ps1')
            Get-Command Install-ConanPackages -ErrorAction SilentlyContinue
        }
        $installCommand | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when conan is unavailable' {
        $output = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'conan' -Available $false
            . (Join-Path $script:ProfileDir 'conan.ps1')
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'conan not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'conan'
    }
}
