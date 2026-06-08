<#
tests/unit/utility-initialize-databases-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/database/initialize-databases.ps1'
}
Describe 'initialize-databases.ps1 extended scenarios' {
    It 'Initializes SQLite databases used by the profile' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'SQLite'
        $c | Should -Match 'Initialize'
    }
    It 'Imports CommandHistory PerformanceMetrics and TestCache database modules' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'CommandHistoryDatabase'
        $c | Should -Match 'PerformanceMetricsDatabase'
        $c | Should -Match 'TestCacheDatabase'
    }
    It 'Uses SqliteDatabase utilities for setup' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'SqliteDatabase\.psm1'
    }
    It 'Uses Exit-WithCode for setup failures' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
    }
}
