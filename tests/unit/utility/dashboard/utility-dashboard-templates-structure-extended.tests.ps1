<#
tests/unit/utility-dashboard-templates-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/modules/DashboardTemplates.psm1'
}
Describe 'scripts/utils/metrics/modules/DashboardTemplates.psm1 structure extended scenarios' {
    It 'Documents dashboard HTML template generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Dashboard HTML template generation utilities'
        $c | Should -Match 'DashboardTemplates.psm1'
    }
    It 'Defines dashboard HTML builders' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-DashboardHtml'
        $c | Should -Match 'Get-DashboardHtmlTemplate'
        $c | Should -Match 'CoverageTrends'
    }
    It 'Exports dashboard template functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HistoricalData'
        $c | Should -Match 'IncludeHistorical'
        $c | Should -Match 'Export-ModuleMember'
    }
}
