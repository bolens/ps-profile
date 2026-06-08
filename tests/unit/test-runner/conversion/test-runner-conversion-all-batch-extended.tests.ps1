<#
tests/unit/test-runner-conversion-all-batch-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-conversion-all-batch.ps1 wrapper behavior.
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
    $script:ConversionAllBatch = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-conversion-all-batch.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'ConversionAllBatchExtended'
}

Describe 'run-conversion-all-batch.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents RepoRoot and RelativePath parameters' {
            $content = Get-Content -LiteralPath $script:ConversionAllBatch -Raw
            $content | Should -Match '\.PARAMETER RepoRoot'
            $content | Should -Match '\.PARAMETER RelativePath'
        }

        It 'Documents PerFile and Parallel switches' {
            $content = Get-Content -LiteralPath $script:ConversionAllBatch -Raw
            $content | Should -Match '\.PARAMETER PerFile'
            $content | Should -Match '\.PARAMETER Parallel'
        }
    }

    Context 'Failure handling' {
        It 'Exits with code 2 when the batch runner script is missing' {
            $fakeRoot = Join-Path $script:TempRoot 'missing-runner-root'
            New-Item -ItemType Directory -Path (Join-Path $fakeRoot 'tests/integration/conversion') -Force | Out-Null

            & pwsh -NoProfile -NonInteractive -File $script:ConversionAllBatch -RepoRoot $fakeRoot 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Exits with code 2 when no conversion batch paths are discovered' {
            $fakeRoot = Join-Path $script:TempRoot 'empty-conversion-root'
            $runnerDir = Join-Path $fakeRoot 'scripts/utils/code-quality'
            $conversionDir = Join-Path $fakeRoot 'tests/integration/conversion'
            New-Item -ItemType Directory -Path $runnerDir -Force | Out-Null
            New-Item -ItemType Directory -Path $conversionDir -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-conversion-integration-batch.ps1') `
                -Destination (Join-Path $runnerDir 'run-conversion-integration-batch.ps1') -Force

            & pwsh -NoProfile -NonInteractive -File $script:ConversionAllBatch -RepoRoot $fakeRoot 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Passes -NonInteractive to sub-batch invocations' {
            $content = Get-Content -LiteralPath $script:ConversionAllBatch -Raw
            $content | Should -Match "'-NonInteractive'"
        }
    }
}
