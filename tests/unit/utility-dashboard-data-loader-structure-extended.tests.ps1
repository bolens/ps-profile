<#
tests/unit/utility-dashboard-data-loader-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/modules/DashboardDataLoader.psm1'
}
Describe 'scripts/utils/metrics/modules/DashboardDataLoader.psm1 structure extended scenarios' {
    It 'Documents dashboard data loading utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Dashboard data loading utilities'
        $c | Should -Match 'DashboardDataLoader.psm1'
    }
    It 'Defines metrics and historical data loaders' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-DashboardMetrics'
        $c | Should -Match 'Get-DashboardHistoricalData'
        $c | Should -Match 'CodeMetrics'
    }
    It 'Loads JSON metrics files from scripts/data' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'code-metrics.json'
        $c | Should -Match 'performance-baseline.json'
        $c | Should -Match 'coverage-trends.json'
    }
}
