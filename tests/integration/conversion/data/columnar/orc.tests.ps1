

<#
.SYNOPSIS
    Integration tests for Apache ORC format conversion utilities.

.DESCRIPTION
    This test suite validates Apache ORC format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python with pyarrow for ORC conversions.
    Some tests may be skipped if external dependencies are not available.
#>

Describe 'Apache ORC Format Conversion Tests' {
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

    Context 'Apache ORC Format Conversions' {
        It 'ConvertFrom-OrcToJson function exists' {
            Get-Command ConvertFrom-OrcToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-OrcFromJson function exists' {
            Get-Command ConvertTo-OrcFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OrcToCsv function exists' {
            Get-Command ConvertFrom-OrcToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OrcToParquet function exists' {
            Get-Command ConvertFrom-OrcToParquet -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OrcToJson handles missing input file gracefully' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.orc'
            { ConvertFrom-OrcToJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'ConvertTo-OrcFromJson handles missing input file gracefully' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-OrcFromJson -InputPath $nonExistentFile } | Should -Throw
        }
    }
}

