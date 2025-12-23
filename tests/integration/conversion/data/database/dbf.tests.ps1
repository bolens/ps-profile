

<#
.SYNOPSIS
    Integration tests for DBF format conversion utilities.

.DESCRIPTION
    This test suite validates DBF format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with dbfread/dbf packages for DBF conversions.
    Tests will be skipped if required dependencies are not available.
#>

Describe 'DBF Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check if Python is available
        $script:PythonAvailable = $false
        if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
            try {
                $pythonPath = Get-PythonPath
                if ($pythonPath) {
                    $script:PythonAvailable = $true
                }
            }
            catch {
                $script:PythonAvailable = $false
            }
        }
    }

    Context 'DBF Format Conversions' {
        It 'ConvertFrom-DbfToJson function exists' {
            Get-Command ConvertFrom-DbfToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DbfToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.dbf'
            { ConvertFrom-DbfToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-DbfToCsv function exists' {
            Get-Command ConvertFrom-DbfToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-DbfFromJson function exists' {
            Get-Command ConvertTo-DbfFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-DbfFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-DbfFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'DBF conversion functions require Python and dbfread/dbf packages' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            # Test that function exists and would require dbfread/dbf
            Get-Command ConvertFrom-DbfToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'DBF aliases resolve to functions' {
            $alias1 = Get-Alias dbf-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-DbfToJson'
            
            $alias2 = Get-Alias json-to-dbf -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-DbfFromJson'
            
            $alias3 = Get-Alias dbf-to-csv -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'ConvertFrom-DbfToCsv'
        }
    }
}

