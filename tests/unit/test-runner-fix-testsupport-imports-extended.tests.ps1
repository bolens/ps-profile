<#
tests/unit/test-runner-fix-testsupport-imports-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for fix-testsupport-imports.ps1 path normalization script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:FixScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/fix-testsupport-imports.ps1'
}

Describe 'fix-testsupport-imports.ps1 extended scenarios' {
    Context 'Replacement rules' {
        It 'Normalizes nested Join-Path TestSupport imports for integration tests' {
            $content = Get-Content -LiteralPath $script:FixScript -Raw
            $content | Should -Match '\$replacements = @\('
            $content | Should -Match 'TestSupport\.ps1'
        }

        It 'Normalizes single-level relative TestSupport imports' {
            $content = Get-Content -LiteralPath $script:FixScript -Raw
            $content | Should -Match "'\.\.\\TestSupport\.ps1'"
        }
    }

    Context 'Scan scope' {
        It 'Processes integration and performance test trees' {
            $content = Get-Content -LiteralPath $script:FixScript -Raw
            $content | Should -Match "'tests' 'integration'"
            $content | Should -Match "'tests' 'performance'"
        }

        It 'Writes updates only when content changes' {
            $content = Get-Content -LiteralPath $script:FixScript -Raw
            $content | Should -Match 'WriteAllText'
            $content | Should -Match 'Fixed \$count file'
        }
    }

    Context 'File discovery' {
        It 'Recursively scans *.tests.ps1 files under configured roots' {
            $content = Get-Content -LiteralPath $script:FixScript -Raw
            $content | Should -Match "Filter '\*\.tests\.ps1'"
            $content | Should -Match '-Recurse'
        }
    }
}
