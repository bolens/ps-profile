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

        It 'Detects roots from ChocolateyPath when lib exists beneath it' {
            $toolsRoot = Join-Path $script:TempDir 'tools-root'
            New-Item -ItemType Directory -Path (Join-Path $toolsRoot 'lib') -Force | Out-Null
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $null
            Mock-EnvironmentVariable -Name 'ChocolateyPath' -Value $toolsRoot

            Get-ChocolateyRoot | Should -Be $toolsRoot
        }
    }

    Context 'Get-ChocolateyLibPath' {
        It 'Uses an explicit ChocolateyRoot parameter without auto-detection' {
            Get-ChocolateyLibPath -ChocolateyRoot $script:FakeChocoRoot |
                Should -Be (Join-Path $script:FakeChocoRoot 'lib')
        }
    }

    Context 'Test-ChocolateyInstalled' {
        It 'Reports not installed when lib directory is missing under the root' {
            $incompleteRoot = Join-Path $script:TempDir 'incomplete-choco'
            New-Item -ItemType Directory -Path $incompleteRoot -Force | Out-Null
            Mock-EnvironmentVariable -Name 'ChocolateyInstall' -Value $incompleteRoot

            Test-ChocolateyInstalled | Should -Be $false
        }
    }
}
