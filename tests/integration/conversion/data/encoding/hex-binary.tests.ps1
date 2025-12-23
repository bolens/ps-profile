

<#
.SYNOPSIS
    Integration tests for Hex and Binary encoding conversions.

.DESCRIPTION
    This test suite validates Hex ↔ Binary conversion functions.

.NOTES
    Tests cover bidirectional conversions and edge cases.
#>

Describe 'Hex and Binary Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Hex to Binary conversions' {
        It 'Converts hex to binary' {
            $result = '4865' | ConvertFrom-HexToBinary
            $result | Should -Be '01001000 01100101'
        }

        It 'Converts hex to binary with custom separator' {
            $result = 'FF' | ConvertFrom-HexToBinary -Separator ''
            $result | Should -Be '11111111'
        }

        It 'Converts hex with spaces to binary' {
            $result = '48 65' | ConvertFrom-HexToBinary
            $result | Should -Be '01001000 01100101'
        }

        It 'Converts empty hex to empty binary' {
            $result = '' | ConvertFrom-HexToBinary
            $result | Should -Be ''
        }

        It 'Throws error for odd-length hex string' {
            { '486' | ConvertFrom-HexToBinary } | Should -Throw
        }
    }

    Context 'Binary to Hex conversions' {
        It 'Converts binary to hex' {
            $result = '01001000 01100101' | ConvertFrom-BinaryToHex
            $result | Should -Be '4865'
        }

        It 'Converts binary without spaces to hex' {
            $result = '11111111' | ConvertFrom-BinaryToHex
            $result | Should -Be 'FF'
        }

        It 'Converts empty binary to empty hex' {
            $result = '' | ConvertFrom-BinaryToHex
            $result | Should -Be ''
        }

        It 'Throws error for invalid binary length' {
            { '0100100' | ConvertFrom-BinaryToHex } | Should -Throw
        }
    }

    Context 'Hex ↔ Binary roundtrip' {
        It 'Hex → Binary → Hex roundtrip' {
            $original = '48656C6C6F'
            $binary = $original | ConvertFrom-HexToBinary
            $result = $binary | ConvertFrom-BinaryToHex
            $result | Should -Be $original
        }
    }
}

