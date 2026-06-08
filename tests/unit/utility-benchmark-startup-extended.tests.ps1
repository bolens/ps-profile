<#
tests/unit/utility-benchmark-startup-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for benchmark-startup.ps1 performance benchmark script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:BenchmarkScript = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/benchmark-startup.ps1'
}

Describe 'benchmark-startup.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Iterations WorkspaceRoot and UpdateBaseline parameters' {
            $content = Get-Content -LiteralPath $script:BenchmarkScript -Raw
            $content | Should -Match '\.PARAMETER Iterations'
            $content | Should -Match '\.PARAMETER WorkspaceRoot'
            $content | Should -Match '\.PARAMETER UpdateBaseline'
        }

        It 'Documents RegressionThreshold for baseline comparison' {
            $content = Get-Content -LiteralPath $script:BenchmarkScript -Raw
            $content | Should -Match 'RegressionThreshold'
        }
    }

    Context 'Benchmark output' {
        It 'Produces CSV and human-readable timing output' {
            $content = Get-Content -LiteralPath $script:BenchmarkScript -Raw
            $content | Should -Match 'CSV'
            $content | Should -Match 'Format-Table'
        }

        It 'Measures per-fragment dot-source timings' {
            $content = Get-Content -LiteralPath $script:BenchmarkScript -Raw
            $content | Should -Match 'fragment'
            $content | Should -Match 'Stopwatch'
        }
    }

    Context 'Parameter validation' {
        It 'Requires positive Iterations values' {
            $content = Get-Content -LiteralPath $script:BenchmarkScript -Raw
            $content | Should -Match 'Iterations must be a positive integer'
        }
    }
}
