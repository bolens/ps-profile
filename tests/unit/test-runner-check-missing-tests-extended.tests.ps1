<#
tests/unit/test-runner-check-missing-tests-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-missing-tests.ps1 module coverage audit script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/check-missing-tests.ps1'
}

Describe 'check-missing-tests.ps1 extended scenarios' {
    Context 'Script structure' {
        It 'Scans scripts/lib modules against library unit tests' {
            $content = Get-Content -LiteralPath $script:CheckScript -Raw
            $content | Should -Match "scripts\\lib"
            $content | Should -Match "tests\\unit"
        }

        It 'Maintains explicit testToModule mapping entries' {
            $content = Get-Content -LiteralPath $script:CheckScript -Raw
            $content | Should -Match 'testToModule'
            $content | Should -Match "'library-path-resolution'"
        }

        It 'Reports modules missing dedicated library tests' {
            $content = Get-Content -LiteralPath $script:CheckScript -Raw
            $content | Should -Match 'Missing tests for'
            $content | Should -Match 'Total modules'
        }
    }

    Context 'Name matching heuristics' {
        It 'Attempts kebab-case to PascalCase module name conversion' {
            $content = Get-Content -LiteralPath $script:CheckScript -Raw
            $content | Should -Match "replace '-', ''"
            $content | Should -Match 'Select-Object -Unique'
        }
    }
}
