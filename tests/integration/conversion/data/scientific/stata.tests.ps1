

<#
.SYNOPSIS
    Integration tests for Stata format conversion utilities.

.DESCRIPTION
    This test suite validates Stata format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with pandas/polars and pyreadstat for Stata conversions.
    Tests will be skipped if Python or required packages are not available.
    Tests verify Get-DataFrameLibraryPreference function and installation recommendations.
#>

Describe 'Stata Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir -TestScriptPath (Join-Path $PSScriptRoot 'stata.tests.ps1')

                foreach ($entry in (Get-ConversionPythonTestContext -ProfileDir $script:ProfileDir -IncludePackageAvailability).GetEnumerator()) {
            Set-Variable -Scope Script -Name $entry.Key -Value $entry.Value
        }
    }

    Context 'Stata Format Conversions' {
        It 'ConvertFrom-StataToJson function exists' {
            Get-Command ConvertFrom-StataToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-StataToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.dta'
            { ConvertFrom-StataToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-StataToCsv function exists' {
            Get-Command ConvertFrom-StataToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-StataFromJson function exists' {
            Get-Command ConvertTo-StataFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-StataFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-StataFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'Stata conversion functions require Python and pandas/polars/pyreadstat' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'python' -ToolType 'python-runtime' -Context 'Python is not available. Install Python to use Stata conversions.')
                return
            }
            # Test that function exists and would require pandas/polars/pyreadstat
            Get-Command ConvertFrom-StataToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
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

        It 'Error messages recommend installing missing packages' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            # Test that error messages include installation recommendations
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.dta'
            $error = { ConvertFrom-StataToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw -PassThru
            
            if ($error) {
                $errorMessage = $error.Exception.Message
                $missingDataFrameLib = -not $script:PandasAvailable -and -not $script:PolarsAvailable
                if ($missingDataFrameLib -or -not $script:PyreadstatAvailable) {
                    ($errorMessage -match 'pandas|polars|pyreadstat') | Should -Be $true
                    ($errorMessage -match 'uv pip install|pip install') | Should -Be $true
                }
                else {
                    ($errorMessage -match 'not found|does not exist|cannot find|InputPath|missing|\.dta') | Should -Be $true
                }
            }
        }

        It 'Provides installation recommendations for missing packages' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $missingPackages = @()
            if (-not $script:PandasAvailable) { $missingPackages += 'pandas' }
            if (-not $script:PolarsAvailable) { $missingPackages += 'polars' }
            if (-not $script:PyreadstatAvailable) { $missingPackages += 'pyreadstat' }
            
            if ($missingPackages.Count -gt 0) {
                foreach ($pkg in $missingPackages) {
                    $recommendation = Get-PythonPackageInstallRecommendation -PackageName $pkg
                    $recommendation | Should -Match $pkg
                    $recommendation | Should -Match '(uv pip install|pip install)'
                }
            }
            else {
                Set-ItResult -Skipped -Because "All required packages are already installed"
            }
        }

        It 'Stata aliases resolve to functions' {
            $alias1 = Get-Alias stata-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-StataToJson'
            
            $alias2 = Get-Alias json-to-stata -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-StataFromJson'
            
            $alias3 = Get-Alias stata-to-csv -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'ConvertFrom-StataToCsv'
        }
    }
}

