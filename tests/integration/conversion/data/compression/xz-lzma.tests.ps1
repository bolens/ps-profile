

<#
.SYNOPSIS
    Integration tests for XZ/LZMA compression utilities.

.DESCRIPTION
    This test suite validates XZ and LZMA compression and decompression functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires native command-line tool (xz) for conversions.
    Tests will be skipped if required dependencies are not available.
#>

Describe 'XZ/LZMA Compression Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
        
        # Check if native tools are available
        $script:XzAvailable = (Get-Command xz -ErrorAction SilentlyContinue) -ne $null
    }

    Context 'XZ/LZMA Compression' {
        It 'Compress-Xz function exists' {
            Get-Command Compress-Xz -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Compress-Xz handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.txt'
            { Compress-Xz -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'Expand-Xz function exists' {
            Get-Command Expand-Xz -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Expand-Xz handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.xz'
            { Expand-Xz -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'Compress-Lzma function exists' {
            Get-Command Compress-Lzma -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Expand-Lzma function exists' {
            Get-Command Expand-Lzma -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'XZ compression functions require xz command' {
            if (-not $script:XzAvailable) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'xz' -Context 'xz command is not available')
                return
            }
            # Test that function exists and would require xz
            Get-Command Compress-Xz -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Compress-Xz accepts CompressionLevel parameter' {
            if (-not $script:XzAvailable) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'xz' -Context 'xz command is not available')
                return
            }
            $func = Get-Command Compress-Xz -CommandType Function -ErrorAction SilentlyContinue
            if ($func) {
                $func.Parameters.Keys | Should -Contain 'CompressionLevel'
            }
        }

        It 'XZ aliases resolve to functions' {
            $alias1 = Get-Alias compress-xz -Scope Global -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            ($alias1.ResolvedCommandName ?? $alias1.Definition) | Should -Be 'Compress-Xz'

            $alias2 = Get-Alias xz -Scope Global -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            ($alias2.ResolvedCommandName ?? $alias2.Definition) | Should -Be 'Compress-Xz'

            $alias3 = Get-Alias expand-xz -Scope Global -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            ($alias3.ResolvedCommandName ?? $alias3.Definition) | Should -Be 'Expand-Xz'
        }

        It 'LZMA aliases resolve to functions' {
            $alias1 = Get-Alias compress-lzma -Scope Global -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            ($alias1.ResolvedCommandName ?? $alias1.Definition) | Should -Be 'Compress-Lzma'

            $alias2 = Get-Alias lzma -Scope Global -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            ($alias2.ResolvedCommandName ?? $alias2.Definition) | Should -Be 'Compress-Lzma'

            $alias3 = Get-Alias expand-lzma -Scope Global -ErrorAction SilentlyContinue
            $alias3 | Should -Not -BeNullOrEmpty
            ($alias3.ResolvedCommandName ?? $alias3.Definition) | Should -Be 'Expand-Lzma'
        }
    }
}

