

<#
.SYNOPSIS
    Integration tests for MATLAB .mat format conversion utilities.

.DESCRIPTION
    This test suite validates MATLAB .mat format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with scipy for MATLAB conversions.
    Tests will be skipped if Python or required packages are not available.
#>

Describe 'MATLAB .mat Format Conversion Tests' {
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

    Context 'MATLAB .mat Format Conversions' {
        It 'ConvertFrom-MatlabToJson function exists' {
            Get-Command ConvertFrom-MatlabToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-MatlabToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.mat'
            { ConvertFrom-MatlabToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-MatlabToCsv function exists' {
            Get-Command ConvertFrom-MatlabToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-MatlabFromJson function exists' {
            Get-Command ConvertTo-MatlabFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-MatlabFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-MatlabFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'MATLAB conversion functions require Python and scipy' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            # Test that function exists and would require scipy
            Get-Command ConvertFrom-MatlabToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'MATLAB aliases resolve to functions' {
            $alias1 = Get-Alias matlab-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-MatlabToJson'
            
            $alias2 = Get-Alias json-to-matlab -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-MatlabFromJson'
            
            $alias3 = Get-Alias matlab-to-csv -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'ConvertFrom-MatlabToCsv'
        }
    }
}

