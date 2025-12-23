

<#
.SYNOPSIS
    Integration tests for ASCII and Hex encoding conversions.

.DESCRIPTION
    This test suite validates ASCII ↔ Hex conversion functions.

.NOTES
    Tests cover bidirectional conversions and edge cases.
#>

Describe 'ASCII and Hex Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'ASCII to Hex conversions' {
        It 'Converts simple ASCII text to hex' {
            $result = 'Hello' | ConvertFrom-AsciiToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be '48656C6C6F'
        }

        It 'Converts empty string to empty hex' {
            $result = '' | ConvertFrom-AsciiToHex
            $result | Should -Be ''
        }

        It 'Converts single character to hex' {
            $result = 'A' | ConvertFrom-AsciiToHex
            $result | Should -Be '41'
        }

        It 'Converts text with spaces to hex' {
            $result = 'Hello World' | ConvertFrom-AsciiToHex
            $result | Should -Be '48656C6C6F20576F726C64'
        }

        It 'Converts special characters to hex' {
            $result = '!@#$%' | ConvertFrom-AsciiToHex
            $result | Should -Not -BeNullOrEmpty
            # Verify roundtrip
            $decoded = $result | ConvertFrom-HexToAscii
            $decoded | Should -Be '!@#$%'
        }
    }

    Context 'Hex to ASCII conversions' {
        It 'Converts hex to ASCII text' {
            $result = '48656C6C6F' | ConvertFrom-HexToAscii
            $result | Should -Be 'Hello'
        }

        It 'Converts hex with spaces to ASCII' {
            $result = '48 65 6C 6C 6F' | ConvertFrom-HexToAscii
            $result | Should -Be 'Hello'
        }

        It 'Converts hex with colons to ASCII' {
            $result = '48:65:6C:6C:6F' | ConvertFrom-HexToAscii
            $result | Should -Be 'Hello'
        }

        It 'Converts empty hex to empty string' {
            $result = '' | ConvertFrom-HexToAscii
            $result | Should -Be ''
        }

        It 'Converts lowercase hex to ASCII' {
            $result = '48656c6c6f' | ConvertFrom-HexToAscii
            $result | Should -Be 'Hello'
        }

        It 'Throws error for odd-length hex string' {
            { '486' | ConvertFrom-HexToAscii } | Should -Throw
        }
    }

    Context 'ASCII ↔ Hex roundtrip' {
        It 'ASCII → Hex → ASCII roundtrip' {
            $original = 'Hello World!'
            $hex = $original | ConvertFrom-AsciiToHex
            $result = $hex | ConvertFrom-HexToAscii
            $result | Should -Be $original
        }

        It 'Handles Unicode characters' {
            $original = 'Hello 世界'
            $hex = $original | ConvertFrom-AsciiToHex
            $result = $hex | ConvertFrom-HexToAscii
            $result | Should -Be $original
        }

        It 'Handles newlines and tabs' {
            $original = "Line1`nLine2`tTabbed"
            $hex = $original | ConvertFrom-AsciiToHex
            $result = $hex | ConvertFrom-HexToAscii
            $result | Should -Be $original
        }

        It 'Handles all printable ASCII characters' {
            $original = ''
            for ($i = 32; $i -le 126; $i++) {
                $original += [char]$i
            }
            $hex = $original | ConvertFrom-AsciiToHex
            $result = $hex | ConvertFrom-HexToAscii
            $result | Should -Be $original
        }

        It 'Handles very long strings' {
            $original = 'A' * 1000
            $hex = $original | ConvertFrom-AsciiToHex
            $result = $hex | ConvertFrom-HexToAscii
            $result | Should -Be $original
        }
    }

    Context 'ASCII ↔ Hex aliases' {
        It 'ascii-to-hex alias works' {
            $result = 'Hello' | ascii-to-hex
            $result | Should -Be '48656C6C6F'
        }

        It 'hex-to-ascii alias works' {
            $result = '48656C6C6F' | hex-to-ascii
            $result | Should -Be 'Hello'
        }
    }
}

