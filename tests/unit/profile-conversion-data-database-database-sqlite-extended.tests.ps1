<#
tests/unit/profile-conversion-data-database-database-sqlite-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/database/database-sqlite.ps1'
}
Describe 'profile.d/conversion-modules/data/database/database-sqlite.ps1 extended scenarios' {
    It 'Documents SQLite database format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'SQLite database format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-DatabaseSqlite with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DatabaseSqlite'
        $c | Should -Match '_ConvertFrom-SqliteToJson'
    }
    It 'Registers sqlite-to-json and db-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'sqlite-to-json'
        $c | Should -Match 'db-to-json'
    }
}
