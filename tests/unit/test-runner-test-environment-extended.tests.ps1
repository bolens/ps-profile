<#
tests/unit/test-runner-test-environment-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestEnvironment detection and health checks.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestEnvironment.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'TestEnvironmentExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestEnvironment extended scenarios' {
    Context 'Get-TestEnvironment' {
        AfterEach {
            if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
                Restore-AllMocks
            }
        }

        It 'Identifies GitHub Actions as the CI provider' {
            Mock-EnvironmentVariable -Name 'GITHUB_ACTIONS' -Value 'true'

            $info = Get-TestEnvironment

            $info.IsCI | Should -Be $true
            $info.CIProvider | Should -Be 'GitHub Actions'
        }

        It 'Detects container environments via container variable' {
            Mock-EnvironmentVariable -Name 'container' -Value 'docker'

            $info = Get-TestEnvironment

            $info.IsContainer | Should -Be $true
        }

        It 'Populates memory information on Linux hosts' {
            if (-not (Test-Path -LiteralPath '/proc/meminfo')) {
                Set-ItResult -Skipped -Because '/proc/meminfo is unavailable on this platform'
                return
            }

            $info = Get-TestEnvironment

            $info.AvailableMemoryGB | Should -Not -BeNullOrEmpty
            $info.AvailableMemoryGB | Should -Not -Be 'Unknown'
        }
    }

    Context 'Test-TestEnvironmentHealth' {
        It 'Fails path checks when repository layout is missing' {
            $health = Test-TestEnvironmentHealth -CheckPaths -RepoRoot $script:TempDir

            $health.Passed | Should -Be $false
            @($health.Checks | Where-Object { $_.Name -eq 'Path: tests' -and -not $_.Passed }).Count | Should -Be 1
            @($health.Checks | Where-Object { $_.Name -eq 'Path: profile.d' -and -not $_.Passed }).Count | Should -Be 1
        }

        It 'Passes path checks for the real repository root' {
            $health = Test-TestEnvironmentHealth -CheckPaths -RepoRoot $script:TestRepoRoot

            $health.Passed | Should -Be $true
            @($health.Checks | Where-Object { $_.Name -like 'Path:*' -and $_.Passed }).Count | Should -Be 2
        }
    }
}
