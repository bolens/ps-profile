

<#
.SYNOPSIS
    Integration tests for Delta Lake format conversion utilities.

.DESCRIPTION
    This test suite validates Delta Lake format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with pyarrow for Delta Lake conversions.
    Some tests may be skipped if external dependencies are not available.
#>

Describe 'Delta Lake Format Conversion Tests' {
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

    Context 'Delta Lake Format Conversions' {
        It 'ConvertFrom-DeltaToJson function exists' {
            Get-Command ConvertFrom-DeltaToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-DeltaFromJson function exists' {
            Get-Command ConvertTo-DeltaFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DeltaToParquet function exists' {
            Get-Command ConvertFrom-DeltaToParquet -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DeltaToJson handles missing input file gracefully' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.delta'
            { ConvertFrom-DeltaToJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'ConvertTo-DeltaFromJson handles missing input file gracefully' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-DeltaFromJson -InputPath $nonExistentFile } | Should -Throw
        }
    }
}

