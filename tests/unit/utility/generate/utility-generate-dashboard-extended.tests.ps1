<#
tests/unit/utility-generate-dashboard-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/generate-dashboard.ps1'
}
Describe 'generate-dashboard.ps1 extended scenarios' {
    It 'Documents IncludeHistorical and DryRun parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'IncludeHistorical'
        $c | Should -Match '\.PARAMETER DryRun'
    }
    It 'Generates HTML dashboard output' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'HTML'
        $c | Should -Match 'metrics-dashboard\.html'
    }
    It 'Defaults historical data path to scripts/data/history' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'scripts/data/history'
    }
    It 'Includes code and performance metric sections' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Code metrics'
        $c | Should -Match 'Performance metrics'
    }
}
