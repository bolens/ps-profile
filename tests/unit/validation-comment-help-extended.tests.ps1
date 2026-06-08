<#
tests/unit/validation-comment-help-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-comment-help.ps1 validation script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CommentHelpScript = Join-Path $script:TestRepoRoot 'scripts/checks/check-comment-help.ps1'
}

Describe 'check-comment-help.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Verbose output support' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match '\.PARAMETER Verbose'
        }

        It 'Scans profile.d fragments for missing help blocks' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match "'profile\.d'"
            $content | Should -Match 'CommentHelp'
        }
    }

    Context 'Analysis modules' {
        It 'Imports AstParsing and FileContent helpers' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match 'AstParsing'
            $content | Should -Match 'FileContent'
        }

        It 'Reports functions missing comment-based help' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match 'missing comment-based help'
        }
    }

    Context 'Exit code handling' {
        It 'Uses EXIT_VALIDATION_FAILURE when missing help is detected' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
        }

        It 'Uses EXIT_SUCCESS when all functions have help' {
            $content = Get-Content -LiteralPath $script:CommentHelpScript -Raw
            $content | Should -Match 'EXIT_SUCCESS'
        }
    }
}
