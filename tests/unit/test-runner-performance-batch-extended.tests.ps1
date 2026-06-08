<#
tests/unit/test-runner-performance-batch-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-performance-batch.ps1 wrapper behavior.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:PerformanceBatchScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-performance-batch.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'PerfBatchExtended'
}

Describe 'run-performance-batch.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Filter and Quiet parameters' {
            $content = Get-Content -LiteralPath $script:PerformanceBatchScript -Raw
            $content | Should -Match '\.PARAMETER Filter'
            $content | Should -Match '\.PARAMETER Quiet'
        }

        It 'Documents per-file execution mode in the description' {
            $content = Get-Content -LiteralPath $script:PerformanceBatchScript -Raw
            $content | Should -Match 'per.*file'
        }
    }

    Context 'Failure handling' {
        It 'Exits with code 2 when the performance test directory is missing' {
            $fakeRoot = Join-Path $script:TempRoot 'missing-perf-dir'
            New-Item -ItemType Directory -Path $fakeRoot -Force | Out-Null

            & pwsh -NoProfile -NonInteractive -File $script:PerformanceBatchScript -RepoRoot $fakeRoot 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Exits with code 2 when the filter matches no test files' {
            & pwsh -NoProfile -NonInteractive -File $script:PerformanceBatchScript -Filter 'zzz-nonexistent-filter-xyz' 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Invokes child runners with -NonInteractive' {
            $content = Get-Content -LiteralPath $script:PerformanceBatchScript -Raw
            $content | Should -Match '-NonInteractive'
        }
    }

    Context 'Get-PesterRunStats parsing' {
        It 'Defines Get-PesterRunStats with quiet and verbose summary patterns' {
            $content = Get-Content -LiteralPath $script:PerformanceBatchScript -Raw
            $content | Should -Match 'function Get-PesterRunStats'
            $content | Should -Match 'Tests completed:'
            $content | Should -Match 'Tests Passed:'
        }
    }
}
