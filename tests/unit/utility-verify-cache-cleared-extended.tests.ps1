<#
tests/unit/utility-verify-cache-cleared-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for verify-cache-cleared.ps1 cache verification script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:VerifyClearedScript = Join-Path $script:TestRepoRoot 'scripts/utils/verify-cache-cleared.ps1'
}

Describe 'verify-cache-cleared.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents cache clearing verification checks' {
            $content = Get-Content -LiteralPath $script:VerifyClearedScript -Raw
            $content | Should -Match 'cache was properly cleared'
            $content | Should -Match 'Database file exists'
        }
    }

    Context 'Verification checks' {
        It 'Inspects SQLite database size and table entry counts' {
            $content = Get-Content -LiteralPath $script:VerifyClearedScript -Raw
            $content | Should -Match 'SQLite'
            $content | Should -Match 'cache table'
        }

        It 'Uses standardized Exit-WithCode handling' {
            $content = Get-Content -LiteralPath $script:VerifyClearedScript -Raw
            $content | Should -Match 'Exit-WithCode'
            $content | Should -Match 'ExitCodes'
        }
    }
}
