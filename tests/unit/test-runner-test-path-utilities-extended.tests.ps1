<#
tests/unit/test-runner-test-path-utilities-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestPathUtilities filtering and shuffling helpers.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestPathUtilities.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'TestPathUtilitiesExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestPathUtilities extended scenarios' {
    Context 'Filter-TestPaths' {
        It 'Deduplicates repeated directory paths' {
            $testFile = Join-Path $script:TempDir 'filter-dedupe.tests.ps1'
            Set-Content -LiteralPath $testFile -Value "Describe 'Dedupe' { It 'runs' { `$true | Should -Be `$true } }" -Encoding UTF8
            $testDir = $script:TempDir

            $result = Filter-TestPaths -TestPaths @($testDir, $testDir) -TestRunnerScriptPath $null

            @($result | Sort-Object) | Should -Be @($result | Sort-Object -Unique)
            $result | Should -Contain $testFile
        }

        It 'Returns sorted unique files when multiple valid files are supplied' {
            $first = Join-Path $script:TempDir 'filter-a.tests.ps1'
            $second = Join-Path $script:TempDir 'filter-b.tests.ps1'
            Set-Content -LiteralPath $first -Value "Describe 'A' { It 'a' { `$true | Should -Be `$true } }" -Encoding UTF8
            Set-Content -LiteralPath $second -Value "Describe 'B' { It 'b' { `$true | Should -Be `$true } }" -Encoding UTF8

            $result = Filter-TestPaths -TestPaths @($second, $first) -TestRunnerScriptPath $null

            $result | Should -Be @($result | Sort-Object)
            $result | Should -Contain $first
            $result | Should -Contain $second
        }

        It 'Returns no paths when every supplied path is missing' {
            $missingA = Join-Path $script:TempDir 'missing-a.tests.ps1'
            $missingB = Join-Path $script:TempDir 'missing-b.tests.ps1'

            $result = Filter-TestPaths -TestPaths @($missingA, $missingB) -TestRunnerScriptPath $null

            @($result).Count | Should -Be 0
        }
    }

    Context 'Get-ShuffledTestPaths' {
        It 'Filters whitespace-only entries before shuffling' {
            $path = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'

            $result = Get-ShuffledTestPaths -TestPaths @($path, '   ')

            @($result).Count | Should -Be 1
            @($result)[0] | Should -Be $path
        }

        It 'Returns two paths when two unique files are supplied' {
            $first = Join-Path $script:TempDir 'shuffle-a.tests.ps1'
            $second = Join-Path $script:TempDir 'shuffle-b.tests.ps1'
            Set-Content -LiteralPath $first -Value "Describe 'A' { It 'a' { `$true | Should -Be `$true } }" -Encoding UTF8
            Set-Content -LiteralPath $second -Value "Describe 'B' { It 'b' { `$true | Should -Be `$true } }" -Encoding UTF8

            $result = Get-ShuffledTestPaths -TestPaths @($first, $second)

            $result.Count | Should -Be 2
            @($result | Sort-Object) | Should -Be @($first, $second | Sort-Object)
        }
    }
}
