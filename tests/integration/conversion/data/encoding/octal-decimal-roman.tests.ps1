

<#
.SYNOPSIS
    Integration tests for Octal, Decimal, and Roman encoding conversions.

.DESCRIPTION
    This test suite validates Octal, Decimal, and Roman numeral conversion functions.

.NOTES
    Tests cover bidirectional conversions and cross-format conversions.
#>

Describe 'Octal, Decimal, and Roman Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'ASCII to Octal conversions' {
        It 'Converts ASCII text to octal' {
            $result = 'Hi' | ConvertFrom-AsciiToOctal
            $result | Should -Be '110 151'
        }

        It 'Converts ASCII to octal with custom separator' {
            $result = 'AB' | ConvertFrom-AsciiToOctal -Separator ''
            $result | Should -Be '101102'
        }

        It 'Converts empty string to empty octal' {
            $result = '' | ConvertFrom-AsciiToOctal
            $result | Should -Be ''
        }
    }

    Context 'Octal to ASCII conversions' {
        It 'Converts octal to ASCII text' {
            $result = '110 151' | ConvertFrom-OctalToAscii
            $result | Should -Be 'Hi'
        }

        It 'Converts octal without spaces to ASCII' {
            $result = '101102' | ConvertFrom-OctalToAscii
            $result | Should -Be 'AB'
        }

        It 'Converts empty octal to empty string' {
            $result = '' | ConvertFrom-OctalToAscii
            $result | Should -Be ''
        }

        It 'Throws error for invalid octal length' {
            { '1101' | ConvertFrom-OctalToAscii } | Should -Throw
        }

        It 'Throws error for invalid octal characters' {
            { '118' | ConvertFrom-OctalToAscii } | Should -Throw
        }
    }

    Context 'ASCII to Decimal conversions' {
        It 'Converts ASCII text to decimal' {
            $result = 'Hi' | ConvertFrom-AsciiToDecimal
            $result | Should -Be '72 105'
        }

        It 'Converts ASCII to decimal with custom separator' {
            $result = 'AB' | ConvertFrom-AsciiToDecimal -Separator ','
            $result | Should -Be '65,66'
        }

        It 'Converts empty string to empty decimal' {
            $result = '' | ConvertFrom-AsciiToDecimal
            $result | Should -Be ''
        }
    }

    Context 'Decimal to ASCII conversions' {
        It 'Converts decimal to ASCII text' {
            $result = '72 105' | ConvertFrom-DecimalToAscii
            $result | Should -Be 'Hi'
        }

        It 'Converts decimal with commas to ASCII' {
            $result = '65,66' | ConvertFrom-DecimalToAscii
            $result | Should -Be 'AB'
        }

        It 'Converts empty decimal to empty string' {
            $result = '' | ConvertFrom-DecimalToAscii
            $result | Should -Be ''
        }

        It 'Throws error for out of range decimal value' {
            { '256' | ConvertFrom-DecimalToAscii } | Should -Throw
        }
    }

    Context 'ASCII to Roman conversions' {
        It 'Converts ASCII text to Roman numerals' {
            $result = 'A' | ConvertFrom-AsciiToRoman
            $result | Should -Be 'LXV'
        }

        It 'Converts ASCII to Roman with custom separator' {
            $result = 'Hi' | ConvertFrom-AsciiToRoman -Separator ','
            $result | Should -Not -BeNullOrEmpty
            $result -match '^[IVXLCDM\s,]+$' | Should -Be $true
        }

        It 'Converts empty string to empty Roman' {
            $result = '' | ConvertFrom-AsciiToRoman
            $result | Should -Be ''
        }
    }

    Context 'Roman to ASCII conversions' {
        It 'Converts Roman numerals to ASCII text' {
            $roman = 'A' | ConvertFrom-AsciiToRoman
            $result = $roman | ConvertFrom-RomanToAscii
            $result | Should -Be 'A'
        }

        It 'Converts Roman with spaces to ASCII' {
            $ascii = 'Hi'
            $roman = $ascii | ConvertFrom-AsciiToRoman
            $result = $roman | ConvertFrom-RomanToAscii
            $result | Should -Be $ascii
        }

        It 'Converts empty Roman to empty string' {
            $result = '' | ConvertFrom-RomanToAscii
            $result | Should -Be ''
        }
    }

    Context 'Cross-format conversions' {
        It 'Hex to Octal conversions' {
            $hex = '4865'
            $octal = $hex | ConvertFrom-HexToOctal
            $result = $octal | ConvertFrom-OctalToHex
            $result | Should -Be $hex
        }

        It 'Hex to Decimal conversions' {
            $hex = '4865'
            $decimal = $hex | ConvertFrom-HexToDecimal
            $result = $decimal | ConvertFrom-DecimalToHex
            $result | Should -Be $hex
        }

        It 'Hex to Roman conversions' {
            $hex = '4865'
            $roman = $hex | ConvertFrom-HexToRoman
            $result = $roman | ConvertFrom-RomanToHex
            $result | Should -Be $hex
        }

        It 'Binary to Octal conversions' {
            $binary = '01001000 01101001'
            $octal = $binary | ConvertFrom-BinaryToOctal
            $result = $octal | ConvertFrom-OctalToBinary
            $result | Should -Be $binary
        }

        It 'Binary to Decimal conversions' {
            $binary = '01001000 01101001'
            $decimal = $binary | ConvertFrom-BinaryToDecimal
            $result = $decimal | ConvertFrom-DecimalToBinary
            $result | Should -Be $binary
        }

        It 'Binary to Roman conversions' {
            $binary = '01001000 01101001'
            $roman = $binary | ConvertFrom-BinaryToRoman
            $result = $roman | ConvertFrom-RomanToBinary
            $result | Should -Be $binary
        }

        It 'ModHex to Octal conversions' {
            $modhex = 'Hello' | ConvertFrom-AsciiToModHex
            $octal = $modhex | ConvertFrom-ModHexToOctal
            $result = $octal | ConvertFrom-OctalToModHex
            $result | Should -Be $modhex
        }

        It 'ModHex to Decimal conversions' {
            $modhex = 'Hello' | ConvertFrom-AsciiToModHex
            $decimal = $modhex | ConvertFrom-ModHexToDecimal
            $result = $decimal | ConvertFrom-DecimalToModHex
            $result | Should -Be $modhex
        }

        It 'ModHex to Roman conversions' {
            $modhex = 'Hello' | ConvertFrom-AsciiToModHex
            $roman = $modhex | ConvertFrom-ModHexToRoman
            $result = $roman | ConvertFrom-RomanToModHex
            $result | Should -Be $modhex
        }

        It 'Octal to Decimal conversions' {
            $octal = '110 151'
            $decimal = $octal | ConvertFrom-OctalToDecimal
            $result = $decimal | ConvertFrom-DecimalToOctal
            $result | Should -Be $octal
        }

        It 'Octal to Roman conversions' {
            $octal = '110 151'
            $roman = $octal | ConvertFrom-OctalToRoman
            $result = $roman | ConvertFrom-RomanToOctal
            $result | Should -Be $octal
        }

        It 'Decimal to Roman conversions' {
            $decimal = '72 105'
            $roman = $decimal | ConvertFrom-DecimalToRoman
            $result = $roman | ConvertFrom-RomanToDecimal
            $result | Should -Be $decimal
        }
    }

    Context 'Complex roundtrips with new formats' {
        It 'ASCII → Octal → Decimal → Roman → Decimal → Octal → ASCII roundtrip' {
            $original = 'Test'
            $octal = $original | ConvertFrom-AsciiToOctal
            $decimal = $octal | ConvertFrom-OctalToDecimal
            $roman = $decimal | ConvertFrom-DecimalToRoman
            $decimal2 = $roman | ConvertFrom-RomanToDecimal
            $octal2 = $decimal2 | ConvertFrom-DecimalToOctal
            $result = $octal2 | ConvertFrom-OctalToAscii
            $result | Should -Be $original
        }

        It 'Hex → Octal → Binary → Roman → Binary → Octal → Hex roundtrip' {
            $original = '48656C6C6F'
            $octal = $original | ConvertFrom-HexToOctal
            $binary = $octal | ConvertFrom-OctalToBinary
            $roman = $binary | ConvertFrom-BinaryToRoman
            $binary2 = $roman | ConvertFrom-RomanToBinary
            $octal2 = $binary2 | ConvertFrom-BinaryToOctal
            $result = $octal2 | ConvertFrom-OctalToHex
            $result | Should -Be $original
        }
    }

    Context 'New format aliases' {
        It 'ascii-to-octal alias works' {
            $result = 'Hi' | ascii-to-octal
            $result | Should -Be '110 151'
        }

        It 'octal-to-ascii alias works' {
            $result = '110 151' | octal-to-ascii
            $result | Should -Be 'Hi'
        }

        It 'ascii-to-decimal alias works' {
            $result = 'Hi' | ascii-to-decimal
            $result | Should -Be '72 105'
        }

        It 'decimal-to-ascii alias works' {
            $result = '72 105' | decimal-to-ascii
            $result | Should -Be 'Hi'
        }

        It 'ascii-to-roman alias works' {
            $result = 'A' | ascii-to-roman
            $result | Should -Be 'LXV'
        }

        It 'roman-to-ascii alias works' {
            $roman = 'A' | ascii-to-roman
            $result = $roman | roman-to-ascii
            $result | Should -Be 'A'
        }
    }
}

