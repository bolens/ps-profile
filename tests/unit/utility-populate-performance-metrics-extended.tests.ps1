<#
tests/unit/utility-populate-performance-metrics-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/database/populate-performance-metrics.ps1'
}
Describe 'populate-performance-metrics.ps1 extended scenarios' {
    It 'Documents populating performance metrics database tables' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'performance metrics'
        $c | Should -Match 'PerformanceMetrics'
    }
    It 'Reads benchmark startup timing via benchmark-startup.ps1' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'benchmark-startup\.ps1'
    }
    It 'Uses SQLite database module imports' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'SqliteDatabase|PerformanceMetricsDatabase'
    }
    It 'Uses Exit-WithCode for population failures' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
    }
}
