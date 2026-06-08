<#
tests/unit/profile-conversion-data-database-database-sql-dump-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/database/database-sql-dump.ps1'
}
Describe 'profile.d/conversion-modules/data/database/database-sql-dump.ps1 extended scenarios' {
    It 'Documents SQL Dump format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'SQL Dump format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-DatabaseSqlDump with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DatabaseSqlDump'
        $c | Should -Match '_ConvertFrom-SqlDumpToJson'
    }
    It 'Registers sql-dump-to-json and sql-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'sql-dump-to-json'
        $c | Should -Match 'sql-to-json'
    }
}
