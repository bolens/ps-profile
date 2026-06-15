<#
tests/unit/test-runner-batch-scripts.tests.ps1

.SYNOPSIS
    Tests for batch test runner wrapper scripts.

.DESCRIPTION
    Validates CLI parameters and basic behavior of per-file batch runners
    without executing the full test suite.
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
    $script:CodeQualityDir = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality'
    $script:BatchScripts = @{
        Unit        = Join-Path $script:CodeQualityDir 'run-unit-batch.ps1'
        Performance = Join-Path $script:CodeQualityDir 'run-performance-batch.ps1'
        Tools       = Join-Path $script:CodeQualityDir 'run-tools-integration-batch.ps1'
        Conversion  = Join-Path $script:CodeQualityDir 'run-conversion-integration-batch.ps1'
        ConversionAll = Join-Path $script:CodeQualityDir 'run-conversion-all-batch.ps1'
    }

    foreach ($entry in $script:BatchScripts.GetEnumerator()) {
        if (-not (Test-Path -LiteralPath $entry.Value)) {
            throw "Batch script not found ($($entry.Key)): $($entry.Value)"
        }
    }
}

Describe 'Batch test runner scripts' {
    Context 'Comment-based help' {
        It 'Documents each batch script' {
            foreach ($scriptPath in $script:BatchScripts.Values) {
                $help = Get-Help $scriptPath -ErrorAction SilentlyContinue
                $help | Should -Not -BeNullOrEmpty
                $help.Synopsis | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'run-unit-batch.ps1' {
        It 'Fails when filter matches no files' {
            $output = & pwsh -NoProfile -File $script:BatchScripts.Unit -RepoRoot $script:TestRepoRoot -Filter 'zzz-no-match-xyz' 2>&1
            $LASTEXITCODE | Should -Not -Be 0
            ($output -join ' ') | Should -Match 'No unit test files matched'
        }

        It 'Documents Quiet switch in comment help' {
            $content = Get-Content -LiteralPath $script:BatchScripts.Unit -Raw
            $content | Should -Match '\.PARAMETER Quiet'
        }
    }

    Context 'run-performance-batch.ps1' {
        It 'Fails when filter matches no files' {
            $output = & pwsh -NoProfile -File $script:BatchScripts.Performance -RepoRoot $script:TestRepoRoot -Filter 'zzz-no-match-xyz' 2>&1
            $LASTEXITCODE | Should -Not -Be 0
            ($output -join ' ') | Should -Match 'No performance test files matched'
        }
    }

    Context 'run-tools-integration-batch.ps1' {
        It 'Fails when relative path does not exist' {
            $output = & pwsh -NoProfile -File $script:BatchScripts.Tools -RepoRoot $script:TestRepoRoot -RelativePath 'missing-subdir-xyz' 2>&1
            $LASTEXITCODE | Should -Not -Be 0
            ($output -join ' ') | Should -Match 'Test directory not found'
        }
    }

    Context 'run-conversion-integration-batch.ps1' {
        It 'Documents Parallel switch in comment help' {
            $content = Get-Content -LiteralPath $script:BatchScripts.Conversion -Raw
            $content | Should -Match '\.PARAMETER Parallel'
        }
    }

    Context 'run-conversion-all-batch.ps1' {
        It 'Documents RelativePath and Parallel switches in comment help' {
            $content = Get-Content -LiteralPath $script:BatchScripts.ConversionAll -Raw
            $content | Should -Match '\.PARAMETER RelativePath'
            $content | Should -Match '\.PARAMETER Parallel'
        }

        It 'Fails when batch runner is missing at RepoRoot' {
            try {
            $fakeRoot = New-TestTempDirectory -Prefix 'ConversionAllMissingRunner'
                        $output = & pwsh -NoProfile -File $script:BatchScripts.ConversionAll -RepoRoot $fakeRoot 2>&1
            $LASTEXITCODE | Should -Be 2
            ($output -join ' ') | Should -Match 'Batch runner not found'
            }
            finally {
                Remove-Item -LiteralPath $fakeRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Runs a single sub-batch via RelativePath using a stub runner' {
            $tempRepo = New-TestTempDirectory -Prefix 'ConversionAllStubRepo'
            try {
                $runnerDir = Join-Path $tempRepo 'scripts/utils/code-quality'
                $conversionDir = Join-Path $tempRepo 'tests/integration/conversion/document'
                New-Item -ItemType Directory -Path $runnerDir -Force | Out-Null
                New-Item -ItemType Directory -Path $conversionDir -Force | Out-Null
                New-Item -ItemType File -Path (Join-Path $conversionDir 'sample.tests.ps1') -Force | Out-Null

                $stubRunner = @'
param([string]$RelativePath)
Write-Host '1P / 0F / 0S'
exit 0
'@
                Set-Content -LiteralPath (Join-Path $runnerDir 'run-conversion-integration-batch.ps1') -Value $stubRunner -Encoding UTF8

                $output = & pwsh -NoProfile -File $script:BatchScripts.ConversionAll -RepoRoot $tempRepo -RelativePath 'document' -Quiet 2>&1
                $LASTEXITCODE | Should -Be 0
                ($output -join ' ') | Should -Match 'Conversion all-batch'
                ($output -join ' ') | Should -Match '1P / 0F / 0S'
            }
            finally {
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
