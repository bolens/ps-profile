

<#
.SYNOPSIS
    Integration tests for Hex and ModHex encoding conversions.

.DESCRIPTION
    This test suite validates Hex ↔ ModHex conversion functions.

.NOTES
    Tests cover bidirectional conversions and edge cases.
#>

Describe 'Hex and ModHex Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Hex to ModHex conversions' {
        It 'Converts hex to ModHex' {
            $result = '4865' | ConvertFrom-HexToModHex
            $result | Should -Not -BeNullOrEmpty
            $result -match '^[cbdefghijklnrtuv]+$' | Should -Be $true
        }

        It 'Converts hex with spaces to ModHex' {
            $result = '48 65' | ConvertFrom-HexToModHex
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Converts empty hex to empty ModHex' {
            $result = '' | ConvertFrom-HexToModHex
            $result | Should -Be ''
        }

        It 'Converts FF to ModHex' {
            $result = 'FF' | ConvertFrom-HexToModHex
            $result | Should -Be 'vv'
        }
    }

    Context 'ModHex to Hex conversions' {
        It 'Converts ModHex to hex' {
            $hex = '4865'
            $modhex = $hex | ConvertFrom-HexToModHex
            $result = $modhex | ConvertFrom-ModHexToHex
            $result | Should -Be $hex
        }

        It 'Converts ModHex with spaces to hex' {
            $hex = 'FF'
            $modhex = $hex | ConvertFrom-HexToModHex
            $modhexWithSpaces = ($modhex -split '(..)' | Where-Object { $_ }) -join ' '
            $result = $modhexWithSpaces | ConvertFrom-ModHexToHex
            $result | Should -Be $hex
        }

        It 'Converts empty ModHex to empty hex' {
            $result = '' | ConvertFrom-ModHexToHex
            $result | Should -Be ''
        }

        It 'Converts vv to FF' {
            $result = 'vv' | ConvertFrom-ModHexToHex
            $result | Should -Be 'FF'
        }
    }

    Context 'Hex ↔ ModHex roundtrip' {
        It 'Hex → ModHex → Hex roundtrip' {
            $original = '48656C6C6F'
            $modhex = $original | ConvertFrom-HexToModHex
            $result = $modhex | ConvertFrom-ModHexToHex
            $result | Should -Be $original
        }
    }
}

