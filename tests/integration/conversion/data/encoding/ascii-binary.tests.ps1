

<#
.SYNOPSIS
    Integration tests for ASCII and Binary encoding conversions.

.DESCRIPTION
    This test suite validates ASCII ↔ Binary conversion functions.

.NOTES
    Tests cover bidirectional conversions and edge cases.
#>

Describe 'ASCII and Binary Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'ASCII to Binary conversions' {
        It 'Converts ASCII text to binary' {
            $result = 'Hi' | ConvertFrom-AsciiToBinary
            $result | Should -Be '01001000 01101001'
        }

        It 'Converts ASCII to binary with custom separator' {
            $result = 'AB' | ConvertFrom-AsciiToBinary -Separator ''
            $result | Should -Be '0100000101000010'
        }

        It 'Converts empty string to empty binary' {
            $result = '' | ConvertFrom-AsciiToBinary
            $result | Should -Be ''
        }

        It 'Converts single character to binary' {
            $result = 'A' | ConvertFrom-AsciiToBinary
            $result | Should -Be '01000001'
        }
    }

    Context 'Binary to ASCII conversions' {
        It 'Converts binary to ASCII text' {
            $result = '01001000 01101001' | ConvertFrom-BinaryToAscii
            $result | Should -Be 'Hi'
        }

        It 'Converts binary without spaces to ASCII' {
            $result = '0100000101000010' | ConvertFrom-BinaryToAscii
            $result | Should -Be 'AB'
        }

        It 'Converts empty binary to empty string' {
            $result = '' | ConvertFrom-BinaryToAscii
            $result | Should -Be ''
        }

        It 'Throws error for invalid binary length' {
            { '0100100' | ConvertFrom-BinaryToAscii } | Should -Throw
        }

        It 'Throws error for invalid binary characters' {
            { '01001002' | ConvertFrom-BinaryToAscii } | Should -Throw
        }
    }

    Context 'ASCII ↔ Binary roundtrip' {
        It 'ASCII → Binary → ASCII roundtrip' {
            $original = 'Test String'
            $binary = $original | ConvertFrom-AsciiToBinary
            $result = $binary | ConvertFrom-BinaryToAscii
            $result | Should -Be $original
        }
    }

    Context 'ASCII ↔ Binary aliases' {
        It 'ascii-to-binary alias works' {
            $result = 'Hi' | ascii-to-binary
            $result | Should -Be '01001000 01101001'
        }

        It 'binary-to-ascii alias works' {
            $result = '01001000 01101001' | binary-to-ascii
            $result | Should -Be 'Hi'
        }
    }
}

