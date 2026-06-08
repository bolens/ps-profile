<#
tests/unit/utility-clear-fragment-cache-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for clear-fragment-cache.ps1 cache clearing script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ClearCacheScript = Join-Path $script:TestRepoRoot 'scripts/utils/clear-fragment-cache.ps1'
}

Describe 'clear-fragment-cache.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents WhatIf IncludeDatabase and IncludeMemoryCache switches' {
            $content = Get-Content -LiteralPath $script:ClearCacheScript -Raw
            $content | Should -Match '\.PARAMETER WhatIf'
            $content | Should -Match 'IncludeDatabase'
            $content | Should -Match 'IncludeMemoryCache'
        }
    }

    Context 'Cache clearing scope' {
        It 'Clears in-memory FragmentContentCache and FragmentAstCache' {
            $content = Get-Content -LiteralPath $script:ClearCacheScript -Raw
            $content | Should -Match 'FragmentContentCache'
            $content | Should -Match 'FragmentAstCache'
        }

        It 'Clears SQLite database cache via Clear-FragmentCache' {
            $content = Get-Content -LiteralPath $script:ClearCacheScript -Raw
            $content | Should -Match 'Clear-FragmentCache'
        }
    }

    Context 'Resilience' {
        It 'Continues clearing remaining components when one step fails' {
            $content = Get-Content -LiteralPath $script:ClearCacheScript -Raw
            $content | Should -Match 'continue'
        }

        It 'Supports selective clearing of memory versus database caches' {
            $content = Get-Content -LiteralPath $script:ClearCacheScript -Raw
            $content | Should -Match 'if \(\$IncludeMemoryCache\)'
            $content | Should -Match 'if \(\$IncludeDatabase\)'
        }
    }
}
