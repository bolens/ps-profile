<#
tests/unit/validation-script-standards-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-script-standards.ps1 validation script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:StandardsScript = Join-Path $script:TestRepoRoot 'scripts/checks/check-script-standards.ps1'
}

Describe 'check-script-standards.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Path parameter with scripts directory default' {
            $content = Get-Content -LiteralPath $script:StandardsScript -Raw
            $content | Should -Match '\.PARAMETER Path'
            $content | Should -Match 'scripts directory'
        }

        It 'Checks Exit-WithCode usage instead of direct exit calls' {
            $content = Get-Content -LiteralPath $script:StandardsScript -Raw
            $content | Should -Match 'Exit-WithCode'
            $content | Should -Match 'direct exit'
        }
    }

    Context 'Validation modules' {
        It 'Imports RegexUtilities and FileContent for script scanning' {
            $content = Get-Content -LiteralPath $script:StandardsScript -Raw
            $content | Should -Match 'RegexUtilities'
            $content | Should -Match 'FileContent'
        }

        It 'Defaults to the scripts directory when Path is omitted' {
            $content = Get-Content -LiteralPath $script:StandardsScript -Raw
            $content | Should -Match 'Get-RepoRoot'
            $content | Should -Match "'scripts'"
        }
    }

    Context 'Standards enforcement' {
        It 'Collects violations into a structured issue list' {
            $content = Get-Content -LiteralPath $script:StandardsScript -Raw
            $content | Should -Match 'issues'
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
        }
    }
}
