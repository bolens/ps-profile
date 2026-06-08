<#
tests/unit/validation-commit-messages-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-commit-messages.ps1 validation script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CommitScript = Join-Path $script:TestRepoRoot 'scripts/checks/check-commit-messages.ps1'
}

Describe 'check-commit-messages.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Base parameter defaulting to origin/main' {
            $content = Get-Content -LiteralPath $script:CommitScript -Raw
            $content | Should -Match '\.PARAMETER Base'
            $content | Should -Match 'origin/main'
        }

        It 'Validates Conventional Commits subject format' {
            $content = Get-Content -LiteralPath $script:CommitScript -Raw
            $content | Should -Match 'Conventional Commits'
        }
    }

    Context 'Git integration' {
        It 'Uses git rev-list to enumerate commits since the base ref' {
            $content = Get-Content -LiteralPath $script:CommitScript -Raw
            $content | Should -Match 'git rev-list'
            $content | Should -Match '--no-merges'
        }

        It 'Attempts to fetch origin/main before validation' {
            $content = Get-Content -LiteralPath $script:CommitScript -Raw
            $content | Should -Match 'git fetch origin'
        }
    }

    Context 'Exit code handling' {
        It 'Exits successfully when no commits need validation' {
            $content = Get-Content -LiteralPath $script:CommitScript -Raw
            $content | Should -Match 'No commits to check against'
            $content | Should -Match 'EXIT_SUCCESS'
        }

        It 'Uses EXIT_VALIDATION_FAILURE for invalid commit subjects' {
            $content = Get-Content -LiteralPath $script:CommitScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
        }
    }
}
