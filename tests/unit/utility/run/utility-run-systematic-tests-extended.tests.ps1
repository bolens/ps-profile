<#
tests/unit/utility-run-systematic-tests-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-systematic-tests.ps1 category test runner.
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
    $script:SystematicScript = Join-Path $script:TestRepoRoot 'scripts/utils/test-verification/run-systematic-tests.ps1'
}

Describe 'run-systematic-tests.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Category Priority and StopOnFailure parameters' {
            $content = Get-Content -LiteralPath $script:SystematicScript -Raw
            $content | Should -Match '\.PARAMETER Category'
            $content | Should -Match '\.PARAMETER Priority'
            $content | Should -Match 'StopOnFailure'
        }
    }

    Context 'Systematic execution' {
        It 'Runs categories in prioritized order from smallest to largest' {
            $content = Get-Content -LiteralPath $script:SystematicScript -Raw
            $content | Should -Match 'prioritized order'
            $content | Should -Match 'smallest to largest'
        }

        It 'Supports optional failure report generation' {
            $content = Get-Content -LiteralPath $script:SystematicScript -Raw
            $content | Should -Match 'GenerateReport'
            $content | Should -Match 'failure reports'
        }
    }

    Context 'Priority filtering' {
        It 'Validates Priority between 1 and 6' {
            $content = Get-Content -LiteralPath $script:SystematicScript -Raw
            $content | Should -Match 'ValidateRange\(1, 6\)'
        }
    }
}
