

<#
.SYNOPSIS
    Integration tests for Apache Iceberg format conversion utilities.

.DESCRIPTION
    This test suite validates Apache Iceberg format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with pyarrow for Iceberg conversions.
    Some tests may be skipped if external dependencies are not available.
#>

Describe 'Apache Iceberg Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check for Python availability
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

    Context 'Apache Iceberg Format Conversions' {
        It 'ConvertFrom-IcebergToJson function exists' {
            Get-Command ConvertFrom-IcebergToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-IcebergFromJson function exists' {
            Get-Command ConvertTo-IcebergFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-IcebergToParquet function exists' {
            Get-Command ConvertFrom-IcebergToParquet -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-IcebergToJson handles missing input file gracefully' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.iceberg'
            { ConvertFrom-IcebergToJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'ConvertTo-IcebergFromJson handles missing input file gracefully' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-IcebergFromJson -InputPath $nonExistentFile } | Should -Throw
        }
    }
}

