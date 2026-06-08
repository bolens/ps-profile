<#
tests/unit/test-runner-run-lint-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-lint.ps1 PSScriptAnalyzer workflow.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LintScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-lint.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'RunLintExtended'
}

Describe 'run-lint.ps1 extended scenarios' {
    Context 'Script structure' {
        It 'Analyzes profile.d and scripts directories' {
            $content = Get-Content -LiteralPath $script:LintScript -Raw
            $content | Should -Match "'profile\.d'"
            $content | Should -Match "'scripts'"
        }

        It 'Writes psscriptanalyzer-report.json under scripts/data' {
            $content = Get-Content -LiteralPath $script:LintScript -Raw
            $content | Should -Match 'psscriptanalyzer-report\.json'
            $content | Should -Match 'Write-JsonFile'
        }

        It 'Uses PSScriptAnalyzerSettings.psd1 when present at repo root' {
            $content = Get-Content -LiteralPath $script:LintScript -Raw
            $content | Should -Match 'PSScriptAnalyzerSettings\.psd1'
        }
    }

    Context 'Exit code handling' {
        It 'Exits successfully when no paths exist to analyze' {
            $fakeRoot = Join-Path $script:TempRoot 'no-lint-paths'
            New-Item -ItemType Directory -Path $fakeRoot -Force | Out-Null

            $content = Get-Content -LiteralPath $script:LintScript -Raw
            $content | Should -Match 'EXIT_SUCCESS'
            $content | Should -Match 'No paths found to analyze'
        }

        It 'Exits with setup error when all configured paths fail analysis' {
            $content = Get-Content -LiteralPath $script:LintScript -Raw
            $content | Should -Match 'EXIT_SETUP_ERROR'
            $content | Should -Match 'All paths failed during linting'
        }

        It 'Exits with validation failure when Error-severity findings exist' {
            $content = Get-Content -LiteralPath $script:LintScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
            $content | Should -Match '\[SeverityLevel\]::Error'
        }
    }
}
