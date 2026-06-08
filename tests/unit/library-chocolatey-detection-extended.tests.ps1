<#
tests/unit/library-chocolatey-detection-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ChocolateyDetection root resolution edge cases.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
    Import-Module (Join-Path $libPath 'core/CommonEnums.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $libPath 'runtime/ChocolateyDetection.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ChocolateyDetectionExtended'
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

Describe 'ChocolateyDetection extended scenarios' {
    AfterEach {
        if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
            Restore-AllMocks
        }
    }

    Context 'Get-ChocolateyRoot' {
        It 'Ignores ChocolateyInstall values that are not directories' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value (Join-Path $script:TempDir 'missing-choco.txt')
            New-Item -ItemType File -Path (Join-Path $script:TempDir 'missing-choco.txt') -Force | Out-Null

            Get-ChocolateyRoot | Should -BeNullOrEmpty
        }

        It 'Detects roots from ChocolateyInstall when lib exists beneath it' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot

            Get-ChocolateyRoot | Should -Be $script:FakeChocoRoot
        }
    }

    Context 'Get-ChocolateyLibPath and Get-ChocolateyBinPath' {
        It 'Uses an explicit ChocolateyRoot parameter without auto-detection' {
            Get-ChocolateyLibPath -ChocolateyRoot $script:FakeChocoRoot |
                Should -Be (Join-Path $script:FakeChocoRoot 'lib')
        }

        It 'Returns null for bin path when the bin directory is missing under an explicit root' {
            $libOnlyRoot = Join-Path $script:TempDir 'lib-only-choco'
            New-Item -ItemType Directory -Path (Join-Path $libOnlyRoot 'lib') -Force | Out-Null

            Get-ChocolateyBinPath -ChocolateyRoot $libOnlyRoot | Should -BeNullOrEmpty
        }
    }

    Context 'Test-ChocolateyInstalled' {
        It 'Requires choco command when CheckCommand is specified' {
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $script:FakeChocoRoot

            Test-ChocolateyInstalled -CheckCommand | Should -Be $false
        }
    }
}
