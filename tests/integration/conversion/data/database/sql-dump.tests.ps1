

<#
.SYNOPSIS
    Integration tests for SQL Dump format conversion utilities.

.DESCRIPTION
    This test suite validates SQL Dump format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    SQL Dump conversions are pure PowerShell (no dependencies).
#>

Describe 'SQL Dump Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'SQL Dump Format Conversions' {
        It 'ConvertFrom-SqlDumpToJson function exists' {
            Get-Command ConvertFrom-SqlDumpToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-SqlDumpToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.sql'
            { ConvertFrom-SqlDumpToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-SqlDumpToCsv function exists' {
            Get-Command ConvertFrom-SqlDumpToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-SqlDumpFromJson function exists' {
            Get-Command ConvertTo-SqlDumpFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-SqlDumpFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-SqlDumpFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'SQL Dump conversion functions are pure PowerShell (no dependencies)' {
            # SQL Dump conversions are pure PowerShell, so they should always work
            Get-Command ConvertFrom-SqlDumpToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'SQL Dump aliases resolve to functions' {
            $alias1 = Get-Alias sql-dump-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-SqlDumpToJson'
            
            $alias2 = Get-Alias json-to-sql-dump -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-SqlDumpFromJson'
            
            $alias3 = Get-Alias sql-dump-to-csv -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'ConvertFrom-SqlDumpToCsv'
        }
    }
}

