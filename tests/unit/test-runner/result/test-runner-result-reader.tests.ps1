<#
tests/unit/test-runner-result-reader.tests.ps1

.SYNOPSIS
    Unit tests for TestResultReader module.
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
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestResultReader.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'TestResultReaderTests'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestResultReader Module' {
    Context 'Get-FailedTestsFromLastRun' {
        It 'Reports when no result directory exists' {
            $result = Get-FailedTestsFromLastRun -TestResultPath (Join-Path $script:TempDir 'missing-results')

            $result.Success | Should -Be $false
            $result.Message | Should -Match 'No test result directory found'
        }

        It 'Parses failed tests from NUnit XML results' {
            $resultsDir = Join-Path $script:TempDir 'results'
            New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

            $xmlPath = Join-Path $resultsDir 'pester-test-result.xml'
            Set-Content -LiteralPath $xmlPath -Value @'
<?xml version="1.0" encoding="utf-8"?>
<test-results>
  <test-case name="Should fail gracefully" result="Failure" />
  <test-case name="Should pass quietly" result="Success" />
</test-results>
'@ -Encoding UTF8

            $result = Get-FailedTestsFromLastRun -TestResultPath $resultsDir

            $result.Success | Should -Be $true
            $result.FailedTests | Should -Contain 'Should fail gracefully'
            $result.FailedTests | Should -Not -Contain 'Should pass quietly'
            $result.Message | Should -Match '1 failed test'
        }
    }

    Context 'Get-TestFilesFromFailedTestNames' {
        It 'Finds test files containing failed test names' {
            $scanDir = Join-Path $script:TempDir 'tests/unit'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null

            $testFile = Join-Path $scanDir 'reader-target.tests.ps1'
            Set-Content -LiteralPath $testFile -Value @"
Describe 'Reader target' {
    It 'Should map back to this file' {
        `$true | Should -Be `$true
    }
}
"@ -Encoding UTF8

            $repoRoot = $script:TempDir
            $files = @(Get-TestFilesFromFailedTestNames -FailedTestNames @('Should map back to this file') -RepoRoot $repoRoot)

            $files | Should -Contain $testFile
        }

        It 'Returns empty array when repo root is invalid' {
            Get-TestFilesFromFailedTestNames -FailedTestNames @('anything') -RepoRoot '' | Should -Be @()
        }
    }
}
