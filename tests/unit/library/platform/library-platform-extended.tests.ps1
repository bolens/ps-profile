<#
tests/unit/library-platform-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Platform detection helpers.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Platform.psm1') -DisableNameChecking -ErrorAction Stop
}

AfterAll {
    Remove-Module Platform -ErrorAction SilentlyContinue -Force
}

Describe 'Platform extended scenarios' {
    Context 'Get-Platform metadata' {
        It 'Includes architecture and OS description fields' {
            $platform = Get-Platform

            $platform.Architecture | Should -Not -BeNullOrEmpty
            $platform.Description | Should -Not -BeNullOrEmpty
        }

        It 'Keeps boolean platform flags aligned with the detected name' {
            $platform = Get-Platform

            switch ($platform.Name) {
                'Windows' { $platform.IsWindows | Should -Be $true }
                'Linux' { $platform.IsLinux | Should -Be $true }
                'macOS' { $platform.IsMacOS | Should -Be $true }
                default {
                    @($platform.IsWindows, $platform.IsLinux, $platform.IsMacOS) |
                        Where-Object { $_ } |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should -BeLessOrEqual 1
                }
            }
        }
    }

    Context 'Platform predicate helpers' {
        It 'Test-IsWindows matches Get-Platform.IsWindows' {
            Test-IsWindows | Should -Be (Get-Platform).IsWindows
        }

        It 'Test-IsLinux matches Get-Platform.IsLinux' {
            Test-IsLinux | Should -Be (Get-Platform).IsLinux
        }

        It 'Test-IsMacOS matches Get-Platform.IsMacOS' {
            Test-IsMacOS | Should -Be (Get-Platform).IsMacOS
        }
    }

    Context 'Platform test environment hooks' {
        AfterEach {
            @(
                'PS_PROFILE_PLATFORM_FORCE_NAME',
                'PS_PROFILE_PLATFORM_FORCE_FALLBACK',
                'PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM',
                'PS_PROFILE_PLATFORM_FORCE_UNAME',
                'PS_PROFILE_PLATFORM_FORCE_NATURAL_WINDOWS',
                'PS_PROFILE_PLATFORM_FORCE_NATURAL_MACOS',
                'PS_PROFILE_PLATFORM_FORCE_NATURAL_FALLBACK',
                'PS_PROFILE_PLATFORM_FORCE_LEGACY_ELSE',
                'PS_PROFILE_PLATFORM_FORCE_FINAL_ELSE'
            ) | ForEach-Object { Remove-Item "Env:$_" -ErrorAction SilentlyContinue }
        }

        It 'Detects forced Windows platform names' {
            $env:PS_PROFILE_PLATFORM_FORCE_NAME = 'Windows'
            $platform = Get-Platform

            $platform.Name | Should -Be 'Windows'
            $platform.IsWindows | Should -Be $true
            Test-IsWindows | Should -Be $true
        }

        It 'Detects forced macOS platform names' {
            $env:PS_PROFILE_PLATFORM_FORCE_NAME = 'macOS'
            $platform = Get-Platform

            $platform.Name | Should -Be 'macOS'
            $platform.IsMacOS | Should -Be $true
            Test-IsMacOS | Should -Be $true
        }

        It 'Uses fallback Unix detection with forced Darwin uname' {
            $env:PS_PROFILE_PLATFORM_FORCE_FALLBACK = '1'
            $env:PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM = 'Unix'
            $env:PS_PROFILE_PLATFORM_FORCE_UNAME = 'Darwin'

            $platform = Get-Platform
            $platform.Name | Should -Be 'macOS'
            $platform.IsMacOS | Should -Be $true
        }

        It 'Uses fallback Unix detection with forced Linux uname' {
            $env:PS_PROFILE_PLATFORM_FORCE_FALLBACK = '1'
            $env:PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM = 'Unix'
            $env:PS_PROFILE_PLATFORM_FORCE_UNAME = 'Linux'

            $platform = Get-Platform
            $platform.Name | Should -Be 'Linux'
            $platform.IsLinux | Should -Be $true
        }

        It 'Uses fallback Win32NT detection for forced Windows fallback' {
            $env:PS_PROFILE_PLATFORM_FORCE_FALLBACK = '1'
            $env:PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM = 'Win32NT'

            $platform = Get-Platform
            $platform.Name | Should -Be 'Windows'
            $platform.IsWindows | Should -Be $true
        }

        It 'Uses natural Windows detection hook for coverage' {
            $env:PS_PROFILE_PLATFORM_FORCE_NATURAL_WINDOWS = '1'
            $platform = Get-Platform

            $platform.Name | Should -Be 'Windows'
            $platform.IsWindows | Should -Be $true
        }

        It 'Uses natural macOS detection hook for coverage' {
            $env:PS_PROFILE_PLATFORM_FORCE_NATURAL_MACOS = '1'
            $platform = Get-Platform

            $platform.Name | Should -Be 'macOS'
            $platform.IsMacOS | Should -Be $true
        }

        It 'Uses natural fallback detection with real uname' {
            $env:PS_PROFILE_PLATFORM_FORCE_NATURAL_FALLBACK = '1'
            $platform = Get-Platform

            $platform.Name | Should -BeIn @('Linux', 'macOS', 'Windows')
        }

        It 'Uses forced fallback with real OS platform and uname' {
            $env:PS_PROFILE_PLATFORM_FORCE_FALLBACK = '1'
            $platform = Get-Platform

            $platform.Name | Should -Not -Be 'Unknown'
        }

        It 'Uses legacy else fallback detection hook' {
            $env:PS_PROFILE_PLATFORM_FORCE_LEGACY_ELSE = '1'
            $platform = Get-Platform

            $platform.Name | Should -BeIn @('Linux', 'macOS', 'Windows')
        }

        It 'Uses legacy else fallback with forced Darwin uname' {
            $env:PS_PROFILE_PLATFORM_FORCE_LEGACY_ELSE = '1'
            $env:PS_PROFILE_PLATFORM_FORCE_UNAME = 'Darwin'
            $platform = Get-Platform

            $platform.Name | Should -Be 'macOS'
            $platform.IsMacOS | Should -Be $true
        }

        It 'Uses natural fallback Win32NT detection hook' {
            $env:PS_PROFILE_PLATFORM_FORCE_NATURAL_FALLBACK = '1'
            $env:PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM = 'Win32NT'
            $platform = Get-Platform

            $platform.Name | Should -Be 'Windows'
            $platform.IsWindows | Should -Be $true
        }

        It 'Uses legacy else fallback Win32NT detection hook' {
            $env:PS_PROFILE_PLATFORM_FORCE_LEGACY_ELSE = '1'
            $env:PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM = 'Win32NT'
            $platform = Get-Platform

            $platform.Name | Should -Be 'Windows'
            $platform.IsWindows | Should -Be $true
        }

        It 'Uses final else fallback detection hook' {
            $env:PS_PROFILE_PLATFORM_FORCE_FINAL_ELSE = '1'
            $platform = Get-Platform

            $platform.Name | Should -BeIn @('Linux', 'macOS', 'Windows')
        }

        It 'Uses final else fallback with forced Darwin uname' {
            $env:PS_PROFILE_PLATFORM_FORCE_FINAL_ELSE = '1'
            $env:PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM = 'Unix'
            $env:PS_PROFILE_PLATFORM_FORCE_UNAME = 'Darwin'
            $platform = Get-Platform

            $platform.Name | Should -Be 'macOS'
            $platform.IsMacOS | Should -Be $true
        }
    }
}
