<#
tests/unit/test-runner-result-reader-failed-names-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-TestFilesFromFailedTestNames matching behavior.
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
    Import-Module (Join-Path $modulePath 'TestResultReader.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestResultReaderFailedNames'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestResultReader failed-name matching extended scenarios' {
    Context 'Get-TestFilesFromFailedTestNames' {
        It 'Returns empty results when the tests directory is missing' {
            $repoRoot = Join-Path $script:TempDir 'repo-without-tests'
            New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null

            @(Get-TestFilesFromFailedTestNames -FailedTestNames @('any test') -RepoRoot $repoRoot) |
                Should -Be @()
        }

        It 'Returns unique files when multiple failed names match the same test file' {
            $scanDir = Join-Path $script:TempDir 'tests' 'unit'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null

            $testFile = Join-Path $scanDir 'shared-target.tests.ps1'
            Set-Content -LiteralPath $testFile -Value @"
Describe 'Shared target' {
    It 'first failing case' { `$true | Should -Be `$true }
    It 'second failing case' { `$true | Should -Be `$true }
}
"@ -Encoding UTF8

            $repoRoot = $script:TempDir
            $files = @(Get-TestFilesFromFailedTestNames -FailedTestNames @('first failing case', 'second failing case') -RepoRoot $repoRoot)

            @($files).Count | Should -Be 1
            $files[0] | Should -Be $testFile
        }

        It 'Matches failed test names containing regex special characters' {
            $scanDir = Join-Path $script:TempDir 'tests' 'integration'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null

            $specialName = 'Should handle [brackets] and (parens)'
            $testFile = Join-Path $scanDir 'special-name.tests.ps1'
            Set-Content -LiteralPath $testFile -Value @"
Describe 'Special name target' {
    It '$specialName' { `$true | Should -Be `$true }
}
"@ -Encoding UTF8

            $files = @(Get-TestFilesFromFailedTestNames -FailedTestNames @($specialName) -RepoRoot $script:TempDir)

            $files | Should -Contain $testFile
        }
    }
}
