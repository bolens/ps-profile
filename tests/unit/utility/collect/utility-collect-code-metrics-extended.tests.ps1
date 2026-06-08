<#
tests/unit/utility-collect-code-metrics-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for collect-code-metrics.ps1 metrics collection script.
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
    $script:MetricsScript = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/collect-code-metrics.ps1'
}

Describe 'collect-code-metrics.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents metrics collection for the repository' {
            $content = Get-Content -LiteralPath $script:MetricsScript -Raw
            $content | Should -Match '\.SYNOPSIS'
            $content | Should -Match 'metrics'
        }
    }

    Context 'Metrics modules' {
        It 'Imports CodeMetrics helpers for repository scanning' {
            $content = Get-Content -LiteralPath $script:MetricsScript -Raw
            $content | Should -Match 'Get-CodeMetrics'
            $content | Should -Match 'Get-CodeQualityScore'
        }

        It 'Uses Get-RepoRoot for repository-relative scanning' {
            $content = Get-Content -LiteralPath $script:MetricsScript -Raw
            $content | Should -Match 'Get-RepoRoot'
        }
    }

    Context 'Output handling' {
        It 'Persists metrics output under scripts/data' {
            $content = Get-Content -LiteralPath $script:MetricsScript -Raw
            $content | Should -Match "'scripts' 'data'"
        }

        It 'Uses standardized Exit-WithCode for failures' {
            $content = Get-Content -LiteralPath $script:MetricsScript -Raw
            $content | Should -Match 'Exit-WithCode'
            $content | Should -Match 'ExitCodes'
        }
    }
}
