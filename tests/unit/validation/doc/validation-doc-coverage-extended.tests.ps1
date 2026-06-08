<#
tests/unit/validation-doc-coverage-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for documentation coverage and freshness checks.
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
    $script:CoverageScript = Join-Path $script:TestRepoRoot 'scripts/checks/check-doc-coverage.ps1'
    $script:FreshnessScript = Join-Path $script:TestRepoRoot 'scripts/checks/check-doc-freshness.ps1'
    $script:DocCoverageModule = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocCoverage.psm1'
}

Describe 'check-doc-coverage.ps1 extended scenarios' {
    It 'Documents Strict and Json switches' {
        $content = Get-Content -LiteralPath $script:CoverageScript -Raw
        $content | Should -Match '\.PARAMETER Strict'
        $content | Should -Match '\.PARAMETER Json'
    }

    It 'Imports DocCoverage reporting module' {
        $content = Get-Content -LiteralPath $script:CoverageScript -Raw
        $content | Should -Match 'DocCoverage\.psm1'
        $content | Should -Match 'Get-DocumentationCoverageReport'
    }

    It 'Uses EXIT_VALIDATION_FAILURE when Strict finds blocking gaps' {
        $content = Get-Content -LiteralPath $script:CoverageScript -Raw
        $content | Should -Match 'EXIT_VALIDATION_FAILURE'
    }
}

Describe 'check-doc-freshness.ps1 extended scenarios' {
    It 'Runs generate-docs.ps1 with Incremental' {
        $content = Get-Content -LiteralPath $script:FreshnessScript -Raw
        $content | Should -Match 'generate-docs\.ps1'
        $content | Should -Match '-Incremental'
    }

    It 'Fails when git detects docs/api changes' {
        $content = Get-Content -LiteralPath $script:FreshnessScript -Raw
        $content | Should -Match 'git status'
        $content | Should -Match 'EXIT_VALIDATION_FAILURE'
    }
}

Describe 'DocCoverage.psm1 extended scenarios' {
    It 'Defines Get-DocumentationCoverageReport' {
        $content = Get-Content -LiteralPath $script:DocCoverageModule -Raw
        $content | Should -Match 'function Get-DocumentationCoverageReport'
        $content | Should -Match 'ParserGaps'
        $content | Should -Match 'RegistrationsWithoutHelp'
    }
}
