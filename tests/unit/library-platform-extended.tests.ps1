<#
tests/unit/library-platform-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Platform detection helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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
}
