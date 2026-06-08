<#
tests/unit/test-runner-result-reader-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestResultReader edge cases.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestResultReader.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestResultReaderExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestResultReader extended scenarios' {
    Context 'Get-FailedTestsFromLastRun' {
        It 'Reports success with empty failures when XML has no failed cases' {
            $resultsDir = Join-Path $script:TempDir 'clean-results'
            New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

            $xmlPath = Join-Path $resultsDir 'pester-test-result.xml'
            Set-Content -LiteralPath $xmlPath -Value @'
<?xml version="1.0" encoding="utf-8"?>
<test-results>
  <test-case name="Should pass quietly" result="Success" />
</test-results>
'@ -Encoding UTF8

            $result = Get-FailedTestsFromLastRun -TestResultPath $resultsDir

            $result.Success | Should -Be $true
            $result.FailedTests | Should -Be @()
            $result.Message | Should -Match '0 failed test'
        }
    }

    Context 'Get-TestFilesFromFailedTestNames' {
        It 'Returns empty array when tests directory is missing under repo root' {
            $emptyRepo = Join-Path $script:TempDir 'no-tests-dir'
            New-Item -ItemType Directory -Path $emptyRepo -Force | Out-Null

            Get-TestFilesFromFailedTestNames -FailedTestNames @('some failure') -RepoRoot $emptyRepo | Should -Be @()
        }

        It 'Skips names that do not appear in any test file' {
            $scanDir = Join-Path $script:TempDir 'tests/unit'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $scanDir 'other.tests.ps1') -Value "It 'unrelated' { `$true | Should -Be `$true }" -Encoding UTF8

            $files = @(Get-TestFilesFromFailedTestNames -FailedTestNames @('missing test name xyz') -RepoRoot $script:TempDir)

            $files | Should -Be @()
        }
    }
}
