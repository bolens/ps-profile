<#
tests/unit/utility-migrate-metrics-to-sqlite-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/database/migrate-metrics-to-sqlite.ps1'
}
Describe 'migrate-metrics-to-sqlite.ps1 extended scenarios' {
    It 'Documents migration of metrics data into SQLite storage' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Migrating performance metrics to SQLite'
    }
    It 'Imports PerformanceMetrics database helpers' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PerformanceMetrics'
    }
    It 'Uses ModuleImport bootstrap pattern' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'ModuleImport'
    }
    It 'Uses Exit-WithCode for migration failures' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
    }
}
