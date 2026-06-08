<#
tests/unit/library-chocolatey-detection.tests.ps1

.SYNOPSIS
    Unit tests for ChocolateyDetection module.
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
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'core/CommonEnums.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $libPath 'runtime/ChocolateyDetection.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ChocolateyDetectionTests'
    $script:FakeChocoRoot = Join-Path $script:TempDir 'chocolatey'
    New-Item -ItemType Directory -Path (Join-Path $script:FakeChocoRoot 'lib') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:FakeChocoRoot 'bin') -Force | Out-Null
}

AfterAll {
    if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
        Restore-AllMocks
    }

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ChocolateyDetection Module' {
    Context 'Get-ChocolateyRoot' {
        AfterEach {
            if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
                Restore-AllMocks
            }
        }

        It 'Returns null when no Chocolatey installation is present' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $null
            Get-ChocolateyRoot | Should -BeNullOrEmpty
        }

        It 'Detects Chocolatey root from ChocolateyInstall environment variable' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot

            Get-ChocolateyRoot | Should -Be $script:FakeChocoRoot
        }
    }

    Context 'Get-ChocolateyLibPath and Get-ChocolateyBinPath' {
        AfterEach {
            if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
                Restore-AllMocks
            }
        }

        It 'Resolves lib and bin directories under the detected root' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot

            Get-ChocolateyLibPath | Should -Be (Join-Path $script:FakeChocoRoot 'lib')
            Get-ChocolateyBinPath | Should -Be (Join-Path $script:FakeChocoRoot 'bin')
        }

        It 'Returns null when Chocolatey root cannot be determined' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $null

            Get-ChocolateyLibPath | Should -BeNullOrEmpty
            Get-ChocolateyBinPath | Should -BeNullOrEmpty
        }
    }

    Context 'Test-ChocolateyInstalled' {
        AfterEach {
            if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
                Restore-AllMocks
            }
        }

        It 'Reports installed when a valid root is detected' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot

            Test-ChocolateyInstalled | Should -Be $true
        }

        It 'Requires choco command when CheckCommand is specified' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot

            Test-ChocolateyInstalled -CheckCommand | Should -Be $false
        }
    }
}
