<#
.SYNOPSIS
    Integration tests for dart tool fragment.

.DESCRIPTION
    Tests dart and flutter helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
}

Describe 'dart Tools Integration Tests' {
    BeforeAll {
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

    Context 'dart helpers (dart.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'dart' -Available $true
            . (Join-Path $script:ProfileDir 'dart.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-DartOutdated function' {
            Get-Command Test-DartOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates dart-outdated alias for Test-DartOutdated' {
            Get-Alias dart-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dart-outdated).ResolvedCommandName | Should -Be 'Test-DartOutdated'
        }

        It 'Test-DartOutdated calls dart pub outdated' {
            Setup-CapturingCommandMock -CommandName 'dart' -Output @(
                'Package    Current  Upgradable  Resolvable'
                'package1  1.0.0    1.2.0       1.2.0'
            )

            Test-DartOutdated
            Assert-TestCommandInvokedExactlyOnce
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
            Setup-CapturingCommandMock -CommandName 'dart' -Output 'Packages upgraded successfully'

            Update-DartPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-DartPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'flutter helpers (dart.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'flutter' -Available $true
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
            Setup-CapturingCommandMock -CommandName 'flutter' -Output @(
                'Package    Current  Upgradable  Resolvable'
                'package1  1.0.0    1.2.0       1.2.0'
            )

            Test-FlutterOutdated
            Assert-TestCommandInvokedExactlyOnce
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
            Setup-CapturingCommandMock -CommandName 'flutter' -Output 'Packages upgraded successfully'

            Update-FlutterPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-FlutterPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when dart is unavailable' {
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

            @(
                'Test-DartOutdated', 'Update-DartPackages', 'Add-DartPackage', 'Remove-DartPackage',
                'Test-FlutterOutdated', 'Update-FlutterPackages', 'Add-FlutterPackage', 'Remove-FlutterPackage'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'dart' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'flutter' -Available $false
            $script:MissingDartOutput = & { . (Join-Path $script:ProfileDir 'dart.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Dart functions are not created when dart is unavailable' {
            Get-Command Test-DartOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when dart is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingDartOutput -Pattern 'dart not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingDartOutput -ToolName 'dart'
        }
    }

    Context 'Graceful degradation when flutter is unavailable' {
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

            @(
                'Test-DartOutdated', 'Update-DartPackages', 'Add-DartPackage', 'Remove-DartPackage',
                'Test-FlutterOutdated', 'Update-FlutterPackages', 'Add-FlutterPackage', 'Remove-FlutterPackage'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'dart' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'flutter' -Available $false
            $script:MissingFlutterOutput = & { . (Join-Path $script:ProfileDir 'dart.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Flutter functions are not created when flutter is unavailable' {
            Get-Command Test-FlutterOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when flutter is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingFlutterOutput -Pattern 'flutter not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingFlutterOutput -ToolName 'flutter'
        }
    }
}
