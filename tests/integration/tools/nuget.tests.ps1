<#
.SYNOPSIS
    Integration tests for NuGet tool fragment.

.DESCRIPTION
    Tests NuGet helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe 'NuGet Tools Integration Tests' {
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
            Write-Error "Failed to initialize NuGet tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'NuGet helpers (nuget.ps1)' {
        BeforeAll {
            # Mock nuget as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'nuget' -Available $true
            . (Join-Path $script:ProfileDir 'nuget.ps1')
        }

        It 'Creates Install-NuGetPackage function' {
            Get-Command Install-NuGetPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nugetinstall alias for Install-NuGetPackage' {
            Get-Alias nugetinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nugetinstall).ResolvedCommandName | Should -Be 'Install-NuGetPackage'
        }

        It 'Creates nugetadd alias for Install-NuGetPackage' {
            Get-Alias nugetadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nugetadd).ResolvedCommandName | Should -Be 'Install-NuGetPackage'
        }

        It 'Install-NuGetPackage calls nuget install' {
            Mock -CommandName nuget -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install') {
                    Write-Output 'Package installed successfully'
                }
            }

            Install-NuGetPackage Newtonsoft.Json
            Should -Invoke -CommandName 'nuget' -Times 1 -Exactly
        }

        It 'Creates Restore-NuGetPackages function' {
            Get-Command Restore-NuGetPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nugetrestore alias for Restore-NuGetPackages' {
            Get-Alias nugetrestore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nugetrestore).ResolvedCommandName | Should -Be 'Restore-NuGetPackages'
        }

        It 'Restore-NuGetPackages calls nuget restore' {
            Mock -CommandName nuget -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'restore') {
                    Write-Output 'Packages restored successfully'
                }
            }

            Restore-NuGetPackages
            Should -Invoke -CommandName 'nuget' -Times 1 -Exactly
        }

        It 'Creates Update-NuGetPackages function' {
            Get-Command Update-NuGetPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nugetupdate alias for Update-NuGetPackages' {
            Get-Alias nugetupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nugetupdate).ResolvedCommandName | Should -Be 'Update-NuGetPackages'
        }

        It 'Update-NuGetPackages calls nuget update' {
            Mock -CommandName nuget -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update') {
                    Write-Output 'Packages updated successfully'
                }
            }

            Update-NuGetPackages
            Should -Invoke -CommandName 'nuget' -Times 1 -Exactly
        }

        It 'Update-NuGetPackages supports -Id parameter for individual packages' {
            Mock -CommandName nuget -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args -contains '-Id' -and $args -contains 'Newtonsoft.Json') {
                    Write-Output 'Newtonsoft.Json updated successfully'
                }
            }

            Update-NuGetPackages -Id Newtonsoft.Json
            Should -Invoke -CommandName 'nuget' -Times 1 -Exactly
        }

    }
}

Describe 'NuGet unavailable graceful degradation' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    }

    It 'Functions are not created when nuget is unavailable' {
        $installCommand = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Mock-CommandAvailabilityPester -CommandName 'nuget' -Available $false
            . (Join-Path $script:ProfileDir 'nuget.ps1')
            Get-Command Install-NuGetPackage -ErrorAction SilentlyContinue
        }
        $installCommand | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when nuget is unavailable' {
        $output = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Mock-CommandAvailabilityPester -CommandName 'nuget' -Available $false
            . (Join-Path $script:ProfileDir 'nuget.ps1')
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'nuget not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'nuget'
    }
}
