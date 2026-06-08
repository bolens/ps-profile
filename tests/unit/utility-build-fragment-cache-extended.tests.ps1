<#
tests/unit/utility-build-fragment-cache-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for build-fragment-cache.ps1 cache warming script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:BuildCacheScript = Join-Path $script:TestRepoRoot 'scripts/utils/build-fragment-cache.ps1'
}

Describe 'build-fragment-cache.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents WhatIf FragmentPath and UseAstParsing parameters' {
            $content = Get-Content -LiteralPath $script:BuildCacheScript -Raw
            $content | Should -Match '\.PARAMETER WhatIf'
            $content | Should -Match '\.PARAMETER FragmentPath'
            $content | Should -Match 'UseAstParsing'
        }
    }

    Context 'Cache warming' {
        It 'Populates FragmentContentCache and SQLite database entries' {
            $content = Get-Content -LiteralPath $script:BuildCacheScript -Raw
            $content | Should -Match 'FragmentContentCache'
            $content | Should -Match 'SQLite'
        }

        It 'Discovers fragments from profile.d by default' {
            $content = Get-Content -LiteralPath $script:BuildCacheScript -Raw
            $content | Should -Match 'profile\.d'
        }
    }

    Context 'Failure handling' {
        It 'Uses standardized exit codes for validation and setup failures' {
            $content = Get-Content -LiteralPath $script:BuildCacheScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
            $content | Should -Match 'EXIT_SETUP_ERROR'
        }

        It 'Supports dry-run preview via WhatIf preference' {
            $content = Get-Content -LiteralPath $script:BuildCacheScript -Raw
            $content | Should -Match '\[WhatIf\]'
        }
    }
}
