

<#
.SYNOPSIS
    Integration tests for ASCII and ModHex encoding conversions.

.DESCRIPTION
    This test suite validates ASCII ↔ ModHex conversion functions.

.NOTES
    Tests cover bidirectional conversions and edge cases.
#>

Describe 'ASCII and ModHex Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'ASCII to ModHex conversions' {
        It 'Converts ASCII text to ModHex' {
            $result = 'Hello' | ConvertFrom-AsciiToModHex
            $result | Should -Not -BeNullOrEmpty
            # Verify it's valid ModHex (only contains c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v)
            $result -match '^[cbdefghijklnrtuv]+$' | Should -Be $true
        }

        It 'Converts empty string to empty ModHex' {
            $result = '' | ConvertFrom-AsciiToModHex
            $result | Should -Be ''
        }

        It 'Converts single character to ModHex' {
            $result = 'A' | ConvertFrom-AsciiToModHex
            $result | Should -Not -BeNullOrEmpty
            $result.Length | Should -Be 2
        }
    }

    Context 'ModHex to ASCII conversions' {
        It 'Converts ModHex to ASCII text' {
            # First convert ASCII to ModHex, then back
            $ascii = 'Hello'
            $modhex = $ascii | ConvertFrom-AsciiToModHex
            $result = $modhex | ConvertFrom-ModHexToAscii
            $result | Should -Be $ascii
        }

        It 'Converts ModHex with spaces to ASCII' {
            $ascii = 'Test'
            $modhex = $ascii | ConvertFrom-AsciiToModHex
            $modhexWithSpaces = ($modhex -split '(..)' | Where-Object { $_ }) -join ' '
            $result = $modhexWithSpaces | ConvertFrom-ModHexToAscii
            $result | Should -Be $ascii
        }

        It 'Converts empty ModHex to empty string' {
            $result = '' | ConvertFrom-ModHexToAscii
            $result | Should -Be ''
        }

        It 'Throws error for odd-length ModHex string' {
            { 'hkkll' | ConvertFrom-ModHexToAscii } | Should -Throw
        }
    }

    Context 'ASCII ↔ ModHex roundtrip' {
        It 'ASCII → ModHex → ASCII roundtrip' {
            $original = 'Hello'
            $modhex = $original | ConvertFrom-AsciiToModHex
            $result = $modhex | ConvertFrom-ModHexToAscii
            $result | Should -Be $original
        }
    }

    Context 'ASCII ↔ ModHex aliases' {
        It 'ascii-to-modhex alias works' {
            $result = 'Hello' | ascii-to-modhex
            $result | Should -Not -BeNullOrEmpty
        }

        It 'modhex-to-ascii alias works' {
            $ascii = 'Hello'
            $modhex = $ascii | ascii-to-modhex
            $result = $modhex | modhex-to-ascii
            $result | Should -Be $ascii
        }
    }
}

