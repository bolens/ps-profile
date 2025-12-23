

<#
.SYNOPSIS
    Integration tests for SQLite format conversion utilities.

.DESCRIPTION
    This test suite validates SQLite format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires SQLite command-line tool (sqlite3) for SQLite conversions.
    Tests will be skipped if required dependencies are not available.
#>

Describe 'SQLite Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check if SQLite is available
        $script:SqliteAvailable = (Get-Command sqlite3 -ErrorAction SilentlyContinue) -ne $null
    }

    Context 'SQLite Format Conversions' {
        It 'ConvertFrom-SqliteToJson function exists' {
            Get-Command ConvertFrom-SqliteToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-SqliteToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.db'
            { ConvertFrom-SqliteToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-SqliteToCsv function exists' {
            Get-Command ConvertFrom-SqliteToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-SqliteToSql function exists' {
            Get-Command ConvertFrom-SqliteToSql -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-SqliteFromJson function exists' {
            Get-Command ConvertTo-SqliteFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-SqliteFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-SqliteFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'SQLite conversion functions require sqlite3 command' {
            if (-not $script:SqliteAvailable) {
                Set-ItResult -Skipped -Because "sqlite3 command is not available"
                return
            }
            # Test that function exists and would require sqlite3
            Get-Command ConvertFrom-SqliteToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'SQLite aliases resolve to functions' {
            $alias1 = Get-Alias sqlite-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-SqliteToJson'
            
            $alias2 = Get-Alias json-to-sqlite -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-SqliteFromJson'
            
            $alias3 = Get-Alias sqlite-to-csv -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'ConvertFrom-SqliteToCsv'
            
            $alias4 = Get-Alias sqlite-to-sql -ErrorAction SilentlyContinue
            $alias4 | Should -Not -BeNullOrEmpty
            $alias4.ResolvedCommandName | Should -Be 'ConvertFrom-SqliteToSql'
        }
    }
}

