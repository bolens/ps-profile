<#
tests/unit/test-runner-unit-batch-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-unit-batch.ps1 wrapper behavior.
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
    $script:UnitBatchScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-unit-batch.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'UnitBatchExtended'
}

Describe 'run-unit-batch.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Filter and Quiet parameters' {
            $content = Get-Content -LiteralPath $script:UnitBatchScript -Raw
            $content | Should -Match '\.PARAMETER Filter'
            $content | Should -Match '\.PARAMETER Quiet'
        }

        It 'Documents per-file execution mode in the description' {
            $content = Get-Content -LiteralPath $script:UnitBatchScript -Raw
            $content | Should -Match 'per.*file'
        }

        It 'Discovers test files recursively under tests/unit' {
            $content = Get-Content -LiteralPath $script:UnitBatchScript -Raw
            $content | Should -Match "Get-ChildItem -Path \`$unitRoot -Filter '\*\.tests\.ps1' -File -Recurse"
        }
    }

    Context 'Failure handling' {
        It 'Exits with code 2 when the unit test directory is missing' {
            $fakeRoot = Join-Path $script:TempRoot 'missing-unit-dir'
            New-Item -ItemType Directory -Path $fakeRoot -Force | Out-Null

            & pwsh -NoProfile -NonInteractive -File $script:UnitBatchScript -RepoRoot $fakeRoot 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Exits with code 2 when the filter matches no test files' {
            & pwsh -NoProfile -NonInteractive -File $script:UnitBatchScript -Filter 'zzz-nonexistent-filter-xyz' 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Invokes child runners with -NonInteractive' {
            $content = Get-Content -LiteralPath $script:UnitBatchScript -Raw
            $content | Should -Match '-NonInteractive'
        }
    }

    Context 'Get-PesterRunStats parsing' {
        It 'Defines Get-PesterRunStats with quiet and verbose summary patterns' {
            $content = Get-Content -LiteralPath $script:UnitBatchScript -Raw
            $content | Should -Match 'function Get-PesterRunStats'
            $content | Should -Match 'Tests completed:'
            $content | Should -Match 'Tests Passed:'
        }
    }
}
