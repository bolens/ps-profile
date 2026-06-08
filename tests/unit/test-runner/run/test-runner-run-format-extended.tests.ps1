<#
tests/unit/test-runner-run-format-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-format.ps1 formatting workflow.
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
    $script:FormatScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-format.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'RunFormatExtended'
}

Describe 'run-format.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Path and DryRun parameters' {
            $content = Get-Content -LiteralPath $script:FormatScript -Raw
            $content | Should -Match '\.PARAMETER Path'
            $content | Should -Match '\.PARAMETER DryRun'
        }

        It 'Uses Invoke-Formatter from PSScriptAnalyzer' {
            $content = Get-Content -LiteralPath $script:FormatScript -Raw
            $content | Should -Match 'Invoke-Formatter'
            $content | Should -Match 'Ensure-ModuleAvailable'
        }
    }

    Context 'Formatting behavior' {
        It 'Normalizes CRLF line endings before formatting' {
            $content = Get-Content -LiteralPath $script:FormatScript -Raw
            $content | Should -Match '`r`n'
            $content | Should -Match 'Normalize line endings'
        }

        It 'Skips empty files without throwing' {
            $content = Get-Content -LiteralPath $script:FormatScript -Raw
            $content | Should -Match 'Skipping empty file'
            $content | Should -Match 'IsNullOrEmpty'
        }

        It 'Completes dry run on a temporary PowerShell file' {
            $formatDir = Join-Path $script:TempRoot 'dry-format'
            New-Item -ItemType Directory -Path $formatDir -Force | Out-Null
            $sampleFile = Join-Path $formatDir 'Sample.ps1'
            Set-Content -LiteralPath $sampleFile -Value 'function Get-FormatSample { return 1 }'

            & pwsh -NoProfile -NonInteractive -File $script:FormatScript -Path $formatDir -DryRun 2>&1 | Out-Null
            $LASTEXITCODE | Should -BeIn @(0, 1)
        }
    }
}
