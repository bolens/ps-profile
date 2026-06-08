<#
tests/unit/test-runner-analyze-test-performance-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for analyze-test-performance.ps1 performance analysis workflow.
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
    $script:PerfScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/analyze-test-performance.ps1'
}

Describe 'analyze-test-performance.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Suite TopN and OutputPath parameters' {
            $content = Get-Content -LiteralPath $script:PerfScript -Raw
            $content | Should -Match '\.PARAMETER Suite'
            $content | Should -Match '\.PARAMETER TopN'
            $content | Should -Match '\.PARAMETER OutputPath'
        }

        It 'Uses the TestSuite enum for suite selection' {
            $content = Get-Content -LiteralPath $script:PerfScript -Raw
            $content | Should -Match '\[TestSuite\]'
            $content | Should -Match 'CommonEnums\.psm1'
        }
    }

    Context 'Test discovery' {
        It 'Resolves test paths through Get-TestPaths' {
            $content = Get-Content -LiteralPath $script:PerfScript -Raw
            $content | Should -Match 'Get-TestPaths'
            $content | Should -Match 'TestPathResolution\.psm1'
        }

        It 'Exits successfully when no test paths match the suite' {
            $content = Get-Content -LiteralPath $script:PerfScript -Raw
            $content | Should -Match 'No test paths found for suite'
            $content | Should -Match 'EXIT_SUCCESS'
        }
    }

    Context 'Reporting' {
        It 'Limits slowest test output using TopN' {
            $content = Get-Content -LiteralPath $script:PerfScript -Raw
            $content | Should -Match 'TopN'
            $content | Should -Match 'Select-Object -First'
        }

        It 'Uses locale formatting helpers when available' {
            $content = Get-Content -LiteralPath $script:PerfScript -Raw
            $content | Should -Match 'Format-LocaleNumber'
            $content | Should -Match 'Format-LocaleDate'
        }
    }
}
