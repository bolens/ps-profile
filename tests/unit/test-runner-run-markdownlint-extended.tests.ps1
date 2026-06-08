<#
tests/unit/test-runner-run-markdownlint-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-markdownlint.ps1 markdown lint workflow.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:MarkdownlintScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-markdownlint.ps1'
}

Describe 'run-markdownlint.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents MARKDOWNLINT_VERSION environment variable' {
            $content = Get-Content -LiteralPath $script:MarkdownlintScript -Raw
            $content | Should -Match 'MARKDOWNLINT_VERSION'
            $content | Should -Match '0\.35\.0'
        }

        It 'Documents exit codes for success validation and setup errors' {
            $content = Get-Content -LiteralPath $script:MarkdownlintScript -Raw
            $content | Should -Match 'EXIT_SUCCESS'
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
            $content | Should -Match 'EXIT_SETUP_ERROR'
        }
    }

    Context 'Execution strategy' {
        It 'Prefers markdownlint command and falls back to npx' {
            $content = Get-Content -LiteralPath $script:MarkdownlintScript -Raw
            $content | Should -Match 'Get-Command markdownlint'
            $content | Should -Match 'Get-Command npx'
            $content | Should -Match 'markdownlint-cli@'
        }

        It 'Ignores node_modules and Modules directories' {
            $content = Get-Content -LiteralPath $script:MarkdownlintScript -Raw
            $content | Should -Match 'node_modules'
            $content | Should -Match 'Modules'
        }

        It 'Attempts global npm install when markdownlint is missing' {
            $content = Get-Content -LiteralPath $script:MarkdownlintScript -Raw
            $content | Should -Match 'npm install -g'
            $content | Should -Match 'Failed to install markdownlint-cli'
        }
    }
}
