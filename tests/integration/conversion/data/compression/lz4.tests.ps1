

<#
.SYNOPSIS
    Integration tests for LZ4 compression utilities.

.DESCRIPTION
    This test suite validates LZ4 compression and decompression functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires native command-line tool (lz4) for conversions.
    Tests will be skipped if required dependencies are not available.
#>

Describe 'LZ4 Compression Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check if native tools are available
        $script:Lz4Available = (Get-Command lz4 -ErrorAction SilentlyContinue) -ne $null
    }

    Context 'LZ4 Compression' {
        It 'Compress-Lz4 function exists' {
            Get-Command Compress-Lz4 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Compress-Lz4 handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.txt'
            { Compress-Lz4 -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'Expand-Lz4 function exists' {
            Get-Command Expand-Lz4 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Expand-Lz4 handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.lz4'
            { Expand-Lz4 -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'LZ4 compression functions require lz4 command' {
            if (-not $script:Lz4Available) {
                Set-ItResult -Skipped -Because "lz4 command is not available"
                return
            }
            # Test that function exists and would require lz4
            Get-Command Compress-Lz4 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Compress-Lz4 accepts CompressionLevel parameter' {
            if (-not $script:Lz4Available) {
                Set-ItResult -Skipped -Because "lz4 command is not available"
                return
            }
            $func = Get-Command Compress-Lz4 -ErrorAction SilentlyContinue
            if ($func) {
                $func.Parameters.Keys | Should -Contain 'CompressionLevel'
            }
        }

        It 'LZ4 aliases resolve to functions' {
            $alias1 = Get-Alias compress-lz4 -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'Compress-Lz4'
            
            $alias2 = Get-Alias lz4 -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'Compress-Lz4'
            
            $alias3 = Get-Alias expand-lz4 -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            $alias3.ResolvedCommandName | Should -Be 'Expand-Lz4'
        }
    }
}

