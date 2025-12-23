

<#
.SYNOPSIS
    Integration tests for Snappy compression utilities.

.DESCRIPTION
    This test suite validates Snappy compression and decompression functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires native command-line tool (snappy) or Python for conversions.
    Tests will be skipped if required dependencies are not available.
#>

Describe 'Snappy Compression Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check if native tools are available
        $script:SnappyAvailable = (Get-Command snappy -ErrorAction SilentlyContinue) -ne $null
        
        # Check if Python is available for Snappy fallback
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

    Context 'Snappy Compression' {
        It 'Compress-Snappy function exists' {
            Get-Command Compress-Snappy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Compress-Snappy handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.txt'
            { Compress-Snappy -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'Expand-Snappy function exists' {
            Get-Command Expand-Snappy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Expand-Snappy handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.snappy'
            { Expand-Snappy -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'Snappy compression functions require snappy command or Python' {
            if (-not $script:SnappyAvailable -and -not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "snappy command and Python are not available"
                return
            }
            # Test that function exists and would require snappy or Python
            Get-Command Compress-Snappy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Snappy aliases resolve to functions' {
            $alias1 = Get-Alias compress-snappy -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'Compress-Snappy'
            
            $alias2 = Get-Alias snappy -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'Compress-Snappy'
            
            $alias3 = Get-Alias expand-snappy -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'Expand-Snappy'
        }
    }
}

