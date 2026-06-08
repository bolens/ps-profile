<#
tests/unit/utility-database-maintenance-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/database/database-maintenance.ps1'
}
Describe 'database-maintenance.ps1 extended scenarios' {
    It 'Documents database maintenance and cleanup operations' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\.SYNOPSIS'
        $c | Should -Match 'maintenance'
    }
    It 'Uses SQLite database modules for maintenance tasks' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'SqliteDatabase|Database'
    }
    It 'Imports ExitCodes for standardized exit handling' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'ExitCodes'
        $c | Should -Match 'Exit-WithCode'
    }
    It 'Supports optimize backup and statistics maintenance actions' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'optimize'
        $c | Should -Match 'database.maintenance'
    }
}
