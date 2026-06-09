<#
tests/unit/test-runner-conversion-integration-batch-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-conversion-integration-batch.ps1 wrapper behavior.
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
    $script:ConversionBatchScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-conversion-integration-batch.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'ConversionBatchExtended'
}

Describe 'run-conversion-integration-batch.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents RelativePath and PerFile parameters' {
            $content = Get-Content -LiteralPath $script:ConversionBatchScript -Raw
            $content | Should -Match '\.PARAMETER RelativePath'
            $content | Should -Match '\.PARAMETER PerFile'
        }

        It 'Documents Parallel execution support' {
            $content = Get-Content -LiteralPath $script:ConversionBatchScript -Raw
            $content | Should -Match '\.PARAMETER Parallel'
        }

        It 'Documents data/structured as the per-file structured conversion example' {
            $content = Get-Content -LiteralPath $script:ConversionBatchScript -Raw
            $content | Should -Match 'data/structured'
            $content | Should -Match '-PerFile'
        }

        It 'Discovers test files recursively under the conversion batch directory' {
            $content = Get-Content -LiteralPath $script:ConversionBatchScript -Raw
            $content | Should -Match "Get-ChildItem -Path \`$testDir -Filter '\*\.tests\.ps1' -File -Recurse"
        }
    }

    Context 'Failure handling' {
        It 'Exits with code 2 when the conversion test directory is missing' {
            $fakeRoot = Join-Path $script:TempRoot 'missing-conversion-dir'
            New-Item -ItemType Directory -Path $fakeRoot -Force | Out-Null

            & pwsh -NoProfile -NonInteractive -File $script:ConversionBatchScript -RepoRoot $fakeRoot 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Exits with code 2 when RelativePath points to a missing subdirectory' {
            & pwsh -NoProfile -NonInteractive -File $script:ConversionBatchScript -RelativePath 'zzz-nonexistent-subdir' 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Invokes child runners through Invoke-ConversionBatchRunner in per-file mode' {
            $content = Get-Content -LiteralPath $script:ConversionBatchScript -Raw
            $content | Should -Match 'function Invoke-ConversionBatchRunner'
            $content | Should -Match 'Invoke-ConversionBatchRunner -RunnerArgs'
        }
    }

    Context 'Get-PesterRunStats parsing' {
        It 'Defines Get-PesterRunStats with XML fallback support' {
            $content = Get-Content -LiteralPath $script:ConversionBatchScript -Raw
            $content | Should -Match 'function Get-PesterRunStats'
            $content | Should -Match 'ResultXmlPath'
        }
    }
}
