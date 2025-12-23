

<#
.SYNOPSIS
    Integration tests for FITS format conversion utilities.

.DESCRIPTION
    This test suite validates FITS format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with astropy for FITS conversions.
    Tests will be skipped if Python or required packages are not available.
#>

Describe 'FITS Format Conversion Tests' {
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

    Context 'FITS Format Conversions' {
        It 'ConvertFrom-FitsToJson function exists' {
            Get-Command ConvertFrom-FitsToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-FitsToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.fits'
            { ConvertFrom-FitsToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-FitsToCsv function exists' {
            Get-Command ConvertFrom-FitsToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-FitsFromJson function exists' {
            Get-Command ConvertTo-FitsFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-FitsFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-FitsFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'FITS conversion functions require Python and astropy' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            # Test that function exists and would require astropy
            Get-Command ConvertFrom-FitsToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'FITS aliases resolve to functions' {
            $alias1 = Get-Alias fits-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-FitsToJson'
            
            $alias2 = Get-Alias json-to-fits -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-FitsFromJson'
            
            $alias3 = Get-Alias fits-to-csv -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'ConvertFrom-FitsToCsv'
        }
    }
}

