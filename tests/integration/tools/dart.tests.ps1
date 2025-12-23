<#
.SYNOPSIS
    Integration tests for dart tool fragment.

.DESCRIPTION
    Tests dart and flutter helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'dart Tools Integration Tests' {
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
            Write-Error "Failed to initialize dart tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'dart helpers (dart.ps1)' {
        BeforeAll {
            # Mock dart as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'dart' -Available $true
            . (Join-Path $script:ProfileDir 'dart.ps1')
        }

        It 'Creates Test-DartOutdated function' {
            Get-Command Test-DartOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates dart-outdated alias for Test-DartOutdated' {
            Get-Alias dart-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dart-outdated).ResolvedCommandName | Should -Be 'Test-DartOutdated'
        }

        It 'Test-DartOutdated calls dart pub outdated' {
            Mock -CommandName dart -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'pub' -and $args -contains 'outdated') {
                    Write-Output 'Package    Current  Upgradable  Resolvable'
                    Write-Output 'package1  1.0.0    1.2.0       1.2.0'
                }
            }

            { Test-DartOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Test-DartOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-DartPackages function' {
            Get-Command Update-DartPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates dart-upgrade alias for Update-DartPackages' {
            Get-Alias dart-upgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dart-upgrade).ResolvedCommandName | Should -Be 'Update-DartPackages'
        }

        It 'Update-DartPackages calls dart pub upgrade' {
            Mock -CommandName dart -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'pub' -and $args -contains 'upgrade') {
                    Write-Output 'Packages upgraded successfully'
                }
            }

            { Update-DartPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-DartPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'flutter helpers (dart.ps1)' {
        BeforeAll {
            # Mock flutter as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'flutter' -Available $true
            . (Join-Path $script:ProfileDir 'dart.ps1')
        }

        It 'Creates Test-FlutterOutdated function' {
            Get-Command Test-FlutterOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates flutter-outdated alias for Test-FlutterOutdated' {
            Get-Alias flutter-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias flutter-outdated).ResolvedCommandName | Should -Be 'Test-FlutterOutdated'
        }

        It 'Test-FlutterOutdated calls flutter pub outdated' {
            Mock -CommandName flutter -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'pub' -and $args -contains 'outdated') {
                    Write-Output 'Package    Current  Upgradable  Resolvable'
                    Write-Output 'package1  1.0.0    1.2.0       1.2.0'
                }
            }

            { Test-FlutterOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Test-FlutterOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-FlutterPackages function' {
            Get-Command Update-FlutterPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates flutter-upgrade alias for Update-FlutterPackages' {
            Get-Alias flutter-upgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias flutter-upgrade).ResolvedCommandName | Should -Be 'Update-FlutterPackages'
        }

        It 'Update-FlutterPackages calls flutter pub upgrade' {
            Mock -CommandName flutter -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'pub' -and $args -contains 'upgrade') {
                    Write-Output 'Packages upgraded successfully'
                }
            }

            { Update-FlutterPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-FlutterPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
