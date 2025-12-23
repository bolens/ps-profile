

<#
.SYNOPSIS
    Integration tests for Binary and ModHex encoding conversions.

.DESCRIPTION
    This test suite validates Binary ↔ ModHex conversion functions.

.NOTES
    Tests cover bidirectional conversions and edge cases.
#>

Describe 'Binary and ModHex Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Binary to ModHex conversions' {
        It 'Converts binary to ModHex' {
            $result = '01001000 01100101' | ConvertFrom-BinaryToModHex
            $result | Should -Not -BeNullOrEmpty
            $result -match '^[cbdefghijklnrtuv]+$' | Should -Be $true
        }

        It 'Converts binary without spaces to ModHex' {
            $result = '0100000101000010' | ConvertFrom-BinaryToModHex
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Converts empty binary to empty ModHex' {
            $result = '' | ConvertFrom-BinaryToModHex
            $result | Should -Be ''
        }
    }

    Context 'ModHex to Binary conversions' {
        It 'Converts ModHex to binary' {
            $binary = '01001000 01100101'
            $modhex = $binary | ConvertFrom-BinaryToModHex
            $result = $modhex | ConvertFrom-ModHexToBinary
            $result | Should -Be $binary
        }

        It 'Converts ModHex with spaces to binary' {
            $binary = '11111111'
            $modhex = $binary | ConvertFrom-BinaryToModHex
            $modhexWithSpaces = ($modhex -split '(..)' | Where-Object { $_ }) -join ' '
            $result = $modhexWithSpaces | ConvertFrom-ModHexToBinary
            $result | Should -Be $binary
        }

        It 'Converts empty ModHex to empty binary' {
            $result = '' | ConvertFrom-ModHexToBinary
            $result | Should -Be ''
        }

        It 'Throws error for odd-length ModHex string' {
            { 'hkkll' | ConvertFrom-ModHexToBinary } | Should -Throw
        }
    }

    Context 'Binary ↔ ModHex roundtrip' {
        It 'Binary → ModHex → Binary roundtrip' {
            $original = '01001000 01100101 01101100 01101100 01101111'
            $modhex = $original | ConvertFrom-BinaryToModHex
            $result = $modhex | ConvertFrom-ModHexToBinary
            $result | Should -Be $original
        }
    }
}

