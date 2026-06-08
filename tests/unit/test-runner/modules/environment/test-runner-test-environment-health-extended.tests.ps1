<#
tests/unit/test-runner-test-environment-health-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestEnvironment health checks and CI detection.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestEnvironment.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'TestEnvironmentHealthExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestEnvironment health extended scenarios' {
    Context 'Get-TestEnvironment' {
        AfterEach {
            if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
                Restore-AllMocks
            }
        }

        It 'Identifies GitLab CI as the CI provider' {
            Mock-EnvironmentVariable -Name 'GITLAB_CI' -Value 'true'

            $info = Get-TestEnvironment

            $info.IsCI | Should -Be $true
            $info.CIProvider | Should -Be 'GitLab CI'
        }

        It 'Identifies Azure DevOps as the CI provider' {
            Mock-EnvironmentVariables -Variables @{
                GITHUB_ACTIONS = $null
                GITLAB_CI      = $null
                JENKINS_HOME   = $null
                CIRCLECI       = $null
                TF_BUILD       = 'True'
            }

            $info = Get-TestEnvironment

            $info.IsCI | Should -Be $true
            $info.CIProvider | Should -Be 'Azure DevOps'
        }

        It 'Reports processor count and PowerShell version metadata' {
            $info = Get-TestEnvironment

            $info.ProcessorCount | Should -BeGreaterThan 0
            $info.PowerShellVersion | Should -Not -BeNullOrEmpty
            $info.OS | Should -Not -BeNullOrEmpty
        }

        It 'Detects git availability through HasGit flag' {
            $info = Get-TestEnvironment
            $expected = [bool](Get-Command git -ErrorAction SilentlyContinue)

            $info.HasGit | Should -Be $expected
        }
    }

    Context 'Test-TestEnvironmentHealth' {
        It 'Passes module checks when Pester is installed' {
            if (-not (Get-Module -ListAvailable -Name Pester -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Pester is not installed on this system'
                return
            }

            $health = Test-TestEnvironmentHealth -CheckModules -RepoRoot $script:TestRepoRoot

            $health.Passed | Should -Be $true
            @($health.Checks | Where-Object { $_.Name -eq 'Module: Pester' -and $_.Passed }).Count | Should -Be 1
        }

        It 'Fails module checks when required modules are absent' {
            $global:TestEnvironmentHealthRepoRoot = $script:TestRepoRoot

            InModuleScope -ModuleName TestEnvironment {
                Mock Get-Module { return $null }

                $health = Test-TestEnvironmentHealth -CheckModules -RepoRoot $global:TestEnvironmentHealthRepoRoot

                $health.Passed | Should -Be $false
                @($health.Checks | Where-Object { $_.Name -eq 'Module: Pester' -and -not $_.Passed }).Count | Should -Be 1
            }
        }

        It 'Passes tool checks when git is available' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available'
                return
            }

            $health = Test-TestEnvironmentHealth -CheckTools -RepoRoot $script:TestRepoRoot

            $health.Passed | Should -Be $true
            @($health.Checks | Where-Object { $_.Name -eq 'Tool: git' -and $_.Passed }).Count | Should -Be 1
        }

        It 'Aggregates failures across multiple check categories' {
            $health = Test-TestEnvironmentHealth -CheckModules -CheckPaths -CheckTools -RepoRoot $script:TempDir

            $health.Passed | Should -Be $false
            @($health.Checks).Count | Should -BeGreaterThan 2
        }
    }
}
