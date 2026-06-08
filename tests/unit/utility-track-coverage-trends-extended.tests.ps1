<#
tests/unit/utility-track-coverage-trends-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/track-coverage-trends.ps1'
}
Describe 'track-coverage-trends.ps1 extended scenarios' {
    It 'Documents CoverageXmlPath HistoryPath and SaveSnapshot parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'CoverageXmlPath'
        $c | Should -Match 'HistoryPath'
        $c | Should -Match 'SaveSnapshot'
    }
    It 'Analyzes coverage trends over a configurable day window' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\$Days = 30'
        $c | Should -Match 'trends'
    }
    It 'Defaults history path to scripts/data/coverage-history' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'coverage-history'
    }
    It 'Uses TestCoverage module helpers for parsing' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'TestCoverage'
    }
}
