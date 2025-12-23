

<#
.SYNOPSIS
    Integration tests for SAS format conversion utilities.

.DESCRIPTION
    This test suite validates SAS format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with pandas/polars and pyreadstat for SAS conversions.
    Tests will be skipped if Python or required packages are not available.
    Tests verify Get-DataFrameLibraryPreference function and installation recommendations.
#>

Describe 'SAS Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Initialize Python mocks if in test mode
        if ($env:PS_PROFILE_TEST_MODE -eq '1' -and (Get-Command Initialize-PythonMocks -ErrorAction SilentlyContinue)) {
            Initialize-PythonMocks -Scenario 'both'
        }
        
        # Check if Python is available (use real check if not mocked)
        $script:PythonAvailable = $false
        $script:PythonCmd = $null
        if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
            try {
                $script:PythonCmd = Get-PythonPath
                if ($script:PythonCmd) {
                    $script:PythonAvailable = $true
                }
            }
            catch {
                $script:PythonAvailable = $false
            }
        }
        
        # Check pandas and polars availability (use real check if not mocked)
        $script:PandasAvailable = $false
        $script:PolarsAvailable = $false
        $script:PyreadstatAvailable = $false
        
        if ($script:PythonAvailable -and $script:PythonCmd) {
            if (Get-Command Test-PythonPackageAvailable -ErrorAction SilentlyContinue) {
                $script:PandasAvailable = Test-PythonPackageAvailable -PackageName 'pandas'
                $script:PolarsAvailable = Test-PythonPackageAvailable -PackageName 'polars'
                $script:PyreadstatAvailable = Test-PythonPackageAvailable -PackageName 'pyreadstat'
            }
        }
    }

    Context 'SAS Format Conversions' {
        It 'ConvertFrom-SasToJson function exists' {
            Get-Command ConvertFrom-SasToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-SasToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.sas7bdat'
            { ConvertFrom-SasToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-SasToCsv function exists' {
            Get-Command ConvertFrom-SasToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-SasFromJson function exists' {
            Get-Command ConvertTo-SasFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-SasFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-SasFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'SAS conversion functions require Python and pandas/polars/pyreadstat' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available. Install Python to use SAS conversions."
                return
            }
            # Test that function exists and would require pandas/polars/pyreadstat
            Get-Command ConvertFrom-SasToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-DataFrameLibraryPreference function exists and works' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            Get-Command Get-DataFrameLibraryPreference -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $script:PythonCmd
            $libInfo | Should -Not -BeNullOrEmpty
            $libInfo.Library | Should -BeIn @('pandas', 'polars')
            $libInfo.Available | Should -BeOfType [bool]
            $libInfo.BothAvailable | Should -BeOfType [bool]
            $libInfo.PandasAvailable | Should -BeOfType [bool]
            $libInfo.PolarsAvailable | Should -BeOfType [bool]
        }

        It 'Get-DataFrameLibraryPreference detects pandas availability correctly' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $script:PythonCmd
            $libInfo.PandasAvailable | Should -Be $script:PandasAvailable
        }

        It 'Get-DataFrameLibraryPreference detects polars availability correctly' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $script:PythonCmd
            $libInfo.PolarsAvailable | Should -Be $script:PolarsAvailable
        }

        It 'Get-DataFrameLibraryPreference respects user preference when both available' {
            if (-not $script:PythonAvailable -or -not $script:PandasAvailable -or -not $script:PolarsAvailable) {
                Set-ItResult -Skipped -Because "Both pandas and polars must be available to test preference"
                return
            }
            
            # Test pandas preference
            $env:PS_DATA_FRAME_LIB = 'pandas'
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $script:PythonCmd
            $libInfo.Library | Should -Be 'pandas'
            $libInfo.Available | Should -Be $true
            
            # Test polars preference
            $env:PS_DATA_FRAME_LIB = 'polars'
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $script:PythonCmd
            $libInfo.Library | Should -Be 'polars'
            $libInfo.Available | Should -Be $true
            
            # Clean up
            Remove-Item Env:\PS_DATA_FRAME_LIB -ErrorAction SilentlyContinue
        }

        It 'Get-DataFrameLibraryPreference falls back when preferred library unavailable' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            # Only test if one is available but not both
            if ($script:PandasAvailable -and -not $script:PolarsAvailable) {
                $env:PS_DATA_FRAME_LIB = 'polars'
                $libInfo = Get-DataFrameLibraryPreference -PythonCmd $script:PythonCmd
                $libInfo.Library | Should -Be 'pandas'  # Should fall back
                $libInfo.Available | Should -Be $true
                Remove-Item Env:\PS_DATA_FRAME_LIB -ErrorAction SilentlyContinue
            }
            elseif ($script:PolarsAvailable -and -not $script:PandasAvailable) {
                $env:PS_DATA_FRAME_LIB = 'pandas'
                $libInfo = Get-DataFrameLibraryPreference -PythonCmd $script:PythonCmd
                $libInfo.Library | Should -Be 'polars'  # Should fall back
                $libInfo.Available | Should -Be $true
                Remove-Item Env:\PS_DATA_FRAME_LIB -ErrorAction SilentlyContinue
            }
            else {
                Set-ItResult -Skipped -Because "Test requires exactly one library (pandas or polars) to be available"
            }
        }

        It 'Error messages recommend installing missing packages' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            # Test that error messages include installation recommendations
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.sas7bdat'
            $error = { ConvertFrom-SasToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw -PassThru
            
            if ($error) {
                $errorMessage = $error.Exception.Message
                # Error should mention pandas/polars or pyreadstat
                ($errorMessage -match 'pandas|polars|pyreadstat') | Should -Be $true
                # Error should include installation recommendation
                ($errorMessage -match 'uv pip install|pip install') | Should -Be $true
            }
        }

        It 'Provides installation recommendations for missing pandas' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            if (-not $script:PandasAvailable) {
                $recommendation = Get-PythonPackageInstallRecommendation -PackageName 'pandas'
                $recommendation | Should -Match 'pandas'
                $recommendation | Should -Match '(uv pip install|pip install)'
            }
            else {
                Set-ItResult -Skipped -Because "pandas is already installed"
            }
        }

        It 'Provides installation recommendations for missing polars' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            if (-not $script:PolarsAvailable) {
                $recommendation = Get-PythonPackageInstallRecommendation -PackageName 'polars'
                $recommendation | Should -Match 'polars'
                $recommendation | Should -Match '(uv pip install|pip install)'
            }
            else {
                Set-ItResult -Skipped -Because "polars is already installed"
            }
        }

        It 'Provides installation recommendations for missing pyreadstat' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            if (-not $script:PyreadstatAvailable) {
                $recommendation = Get-PythonPackageInstallRecommendation -PackageName 'pyreadstat'
                $recommendation | Should -Match 'pyreadstat'
                $recommendation | Should -Match '(uv pip install|pip install)'
            }
            else {
                Set-ItResult -Skipped -Because "pyreadstat is already installed"
            }
        }

        It 'SAS aliases resolve to functions' {
            $alias1 = Get-Alias sas-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-SasToJson'
            
            $alias2 = Get-Alias json-to-sas -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-SasFromJson'
            
            $alias3 = Get-Alias sas-to-csv -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'ConvertFrom-SasToCsv'
        }
    }
}

