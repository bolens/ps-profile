

<#
.SYNOPSIS
    Integration tests for Microsoft Access format conversion utilities.

.DESCRIPTION
    This test suite validates Microsoft Access format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with pyodbc and Microsoft Access Database Engine (ACE) for Access conversions.
    Tests will be skipped if required dependencies are not available.
#>

Describe 'Microsoft Access Format Conversion Tests' {
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

    Context 'Microsoft Access Format Conversions' {
        It 'ConvertFrom-AccessToJson function exists' {
            Get-Command ConvertFrom-AccessToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-AccessToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.mdb'
            { ConvertFrom-AccessToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-AccessToCsv function exists' {
            Get-Command ConvertFrom-AccessToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-AccessFromJson function exists' {
            Get-Command ConvertTo-AccessFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-AccessFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-AccessFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'Access conversion functions require Python, pyodbc, and Access Database Engine' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            # Test that function exists and would require pyodbc and ACE
            Get-Command ConvertFrom-AccessToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Access aliases resolve to functions' {
            $alias1 = Get-Alias access-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-AccessToJson'
            
            $alias2 = Get-Alias json-to-access -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-AccessFromJson'
            
            $alias3 = Get-Alias access-to-csv -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'ConvertFrom-AccessToCsv'
        }
    }
}

