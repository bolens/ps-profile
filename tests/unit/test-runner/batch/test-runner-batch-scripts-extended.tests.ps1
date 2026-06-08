<#
tests/unit/test-runner-batch-scripts-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for batch test runner wrapper scripts.
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
    }
}

Describe 'Batch test runner extended scenarios' {
    Context 'Parameter documentation' {
        It 'Documents RepoRoot in unit and performance batch scripts' {
            foreach ($scriptPath in @($script:BatchScripts.Unit, $script:BatchScripts.Performance)) {
                $content = Get-Content -LiteralPath $scriptPath -Raw
                $content | Should -Match '\.PARAMETER RepoRoot'
            }
        }

        It 'Documents Filter in the unit batch script' {
            $content = Get-Content -LiteralPath $script:BatchScripts.Unit -Raw
            $content | Should -Match '\.PARAMETER Filter'
        }

        It 'Documents RelativePath in tools and conversion batch scripts' {
            foreach ($scriptPath in @($script:BatchScripts.Tools, $script:BatchScripts.Conversion)) {
                $content = Get-Content -LiteralPath $scriptPath -Raw
                $content | Should -Match '\.PARAMETER RelativePath'
            }
        }
    }

    Context 'Failure handling' {
        It 'Exits with code 2 when the unit test directory is missing' {
            $fakeRoot = New-TestTempDirectory -Prefix 'BatchMissingUnitDir'
            try {
                & pwsh -NoProfile -File $script:BatchScripts.Unit -RepoRoot $fakeRoot 2>&1 | Out-Null
                $LASTEXITCODE | Should -Be 2
            }
            finally {
                Remove-Item -LiteralPath $fakeRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Exits with code 2 when the performance test directory is missing' {
            $fakeRoot = New-TestTempDirectory -Prefix 'BatchMissingPerfDir'
            try {
                & pwsh -NoProfile -File $script:BatchScripts.Performance -RepoRoot $fakeRoot 2>&1 | Out-Null
                $LASTEXITCODE | Should -Be 2
            }
            finally {
                Remove-Item -LiteralPath $fakeRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'run-conversion-all-batch.ps1' {
        It 'Documents Quiet switch in comment help' {
            $conversionAll = Join-Path $script:CodeQualityDir 'run-conversion-all-batch.ps1'
            Test-Path -LiteralPath $conversionAll | Should -Be $true
            $content = Get-Content -LiteralPath $conversionAll -Raw
            $content | Should -Match '\.PARAMETER Quiet'
        }
    }
}
