<#
tests/unit/test-runner-test-lister.tests.ps1

.SYNOPSIS
    Unit tests for TestLister module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestLister.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'TestListerTests'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestLister Module' {
    Context 'Get-TestList' {
        It 'Parses Describe, Context, and It blocks from a test file' {
            $testFile = Join-Path $script:TempDir 'sample.tests.ps1'
            Set-Content -LiteralPath $testFile -Value @"
Describe 'Sample suite' {
    Context 'When ready' {
        It 'runs the first case' {
            `$true | Should -Be `$true
        }

        It 'runs the second case' {
            `$true | Should -Be `$true
        }
    }
}
"@ -Encoding UTF8

            $list = Get-TestList -TestPaths @($testFile) -RepoRoot $script:TestRepoRoot

            $list.TestFiles | Should -Contain $testFile
            $list.TestCount | Should -Be 2

            $tests = @($list.Tests)
            $tests.Count | Should -Be 2
            $tests[0].Describe | Should -Be 'Sample suite'
            $tests[0].Context | Should -Be 'When ready'
            ($tests.Name -contains 'runs the first case') | Should -Be $true
        }

        It 'Skips missing paths without throwing' {
            $list = Get-TestList -TestPaths @('/tmp/does-not-exist-xyz.tests.ps1') -RepoRoot $script:TestRepoRoot

            $list.TestCount | Should -Be 0
            @($list.TestFiles).Count | Should -Be 0
        }
    }

    Context 'Show-TestList' {
        It 'Writes discovery output without error' {
            $testFile = Join-Path $script:TempDir 'display.tests.ps1'
            Set-Content -LiteralPath $testFile -Value @"
Describe 'Display suite' {
    It 'shows output' { `$true | Should -Be `$true }
}
"@ -Encoding UTF8

            $list = Get-TestList -TestPaths @($testFile) -RepoRoot $script:TestRepoRoot

            { Show-TestList -TestList $list -ShowDetails } | Should -Not -Throw
        }
    }
}
