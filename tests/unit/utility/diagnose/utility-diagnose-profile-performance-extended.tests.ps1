<#
tests/unit/utility-diagnose-profile-performance-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for diagnose-profile-performance.ps1 performance diagnostics script.
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
    $script:DiagnoseScript = Join-Path $script:TestRepoRoot 'scripts/utils/performance/diagnose-profile-performance.ps1'
}

Describe 'diagnose-profile-performance.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents profile load time diagnostics' {
            $content = Get-Content -LiteralPath $script:DiagnoseScript -Raw
            $content | Should -Match 'profile loading performance'
            $content | Should -Match 'slow fragments'
        }
    }

    Context 'Diagnostic methods' {
        It 'Tests profile loading with performance profiling enabled' {
            $content = Get-Content -LiteralPath $script:DiagnoseScript -Raw
            $content | Should -Match 'performance profiling'
            $content | Should -Match 'Microsoft\.PowerShell_profile\.ps1'
        }

        It 'Provides optimization recommendations' {
            $content = Get-Content -LiteralPath $script:DiagnoseScript -Raw
            $content | Should -Match 'recommendations'
        }
    }

    Context 'Module imports' {
        It 'Uses PathResolution and Logging helpers when available' {
            $content = Get-Content -LiteralPath $script:DiagnoseScript -Raw
            $content | Should -Match 'PathResolution'
            $content | Should -Match 'Logging'
        }
    }
}
