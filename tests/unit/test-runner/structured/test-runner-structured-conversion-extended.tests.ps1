<#
tests/unit/test-runner-structured-conversion-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-structured-conversion-tests.ps1 wrapper behavior.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:StructuredScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-structured-conversion-tests.ps1'
    $script:StructuredTestDir = Join-Path $script:TestRepoRoot 'tests/integration/conversion/data/structured'
}

Describe 'run-structured-conversion-tests.ps1 extended scenarios' {
    Context 'Script structure' {
        It 'Targets the structured conversion integration directory' {
            $content = Get-Content -LiteralPath $script:StructuredScript -Raw
            $content | Should -Match "'conversion' 'data' 'structured'"
        }

        It 'Runs one Pester process per structured test file' {
            $content = Get-Content -LiteralPath $script:StructuredScript -Raw
            $content | Should -Match 'foreach \(\$file in \$files\)'
        }

        It 'Invokes run-pester with the Integration suite' {
            $content = Get-Content -LiteralPath $script:StructuredScript -Raw
            $content | Should -Match "'Integration'"
        }
    }

    Context 'RepoRoot parameter' {
        It 'Accepts RepoRoot to locate structured conversion tests' {
            $content = Get-Content -LiteralPath $script:StructuredScript -Raw
            $content | Should -Match 'RepoRoot'
            $content | Should -Match 'structured'
        }
    }

    Context 'Result parsing' {
        It 'Parses quiet-mode Tests completed summary lines' {
            $content = Get-Content -LiteralPath $script:StructuredScript -Raw
            $content | Should -Match 'Tests completed:'
            $content | Should -Match 'Tests Passed:'
        }

        It 'Captures failed test lines for the summary table' {
            $content = Get-Content -LiteralPath $script:StructuredScript -Raw
            $content | Should -Match 'FailLines'
            $content | Should -Match 'Format-Table'
        }
    }
}
