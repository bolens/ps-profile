<#
tests/unit/utility-verify-cache-load-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for verify-cache-load.ps1 cache load verification script.
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
    $script:VerifyLoadScript = Join-Path $script:TestRepoRoot 'scripts/utils/verify-cache-load.ps1'
}

Describe 'verify-cache-load.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents cache load verification during profile initialization' {
            $content = Get-Content -LiteralPath $script:VerifyLoadScript -Raw
            $content | Should -Match 'properly loaded during profile initialization'
            $content | Should -Match 'Cache variables are initialized'
        }
    }

    Context 'Diagnostics' {
        It 'Enables detailed debug output for cache inspection' {
            $content = Get-Content -LiteralPath $script:VerifyLoadScript -Raw
            $content | Should -Match "PS_PROFILE_DEBUG = '3'"
        }

        It 'Checks SQLite database accessibility and cache hit rates' {
            $content = Get-Content -LiteralPath $script:VerifyLoadScript -Raw
            $content | Should -Match 'SQLite'
            $content | Should -Match 'Cache hit'
        }
    }
}
