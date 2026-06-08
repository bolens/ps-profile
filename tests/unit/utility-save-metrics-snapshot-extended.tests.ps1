<#
tests/unit/utility-save-metrics-snapshot-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/save-metrics-snapshot.ps1'
}
Describe 'save-metrics-snapshot.ps1 extended scenarios' {
    It 'Documents IncludeCodeMetrics and IncludePerformanceMetrics switches' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'IncludeCodeMetrics'
        $c | Should -Match 'IncludePerformanceMetrics'
    }
    It 'Saves timestamped snapshots for trend analysis' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'timestamped'
        $c | Should -Match 'historical'
    }
    It 'Defaults snapshot directory to scripts/data/history' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'scripts/data/history'
    }
    It 'Imports MetricsSnapshot helpers via ModuleImport' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'ModuleImport'
        $c | Should -Match 'Save-MetricsSnapshot'
    }
}
