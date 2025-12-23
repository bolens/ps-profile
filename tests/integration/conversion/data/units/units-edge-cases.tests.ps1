

<#
.SYNOPSIS
    Integration tests for unit conversion edge cases and error handling.

.DESCRIPTION
    This test suite validates edge cases and error handling for all unit conversion functions.

.NOTES
    Tests cover zero values, negative values, and very large values across all unit types.
#>

Describe 'Unit Conversion Edge Cases and Error Handling Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Edge Cases and Error Handling' {
        It 'All unit conversion functions handle zero values' {
            $length = Convert-Length -Value 0 -FromUnit 'm' -ToUnit 'ft'
            $length.Value | Should -Be 0

            $weight = Convert-Weight -Value 0 -FromUnit 'kg' -ToUnit 'lb'
            $weight.Value | Should -Be 0

            $temp = Convert-Temperature -Value 0 -FromUnit 'C' -ToUnit 'F'
            $temp.Value | Should -Be 32

            $volume = Convert-Volume -Value 0 -FromUnit 'l' -ToUnit 'gal'
            $volume.Value | Should -Be 0
        }

        It 'All unit conversion functions handle negative values' {
            $length = Convert-Length -Value -10 -FromUnit 'm' -ToUnit 'ft'
            $length.Value | Should -BeLessThan 0

            $temp = Convert-Temperature -Value -10 -FromUnit 'C' -ToUnit 'F'
            $temp.Value | Should -BeLessThan 32
        }

        It 'All unit conversion functions handle very large values' {
            $length = Convert-Length -Value 1000000 -FromUnit 'km' -ToUnit 'mi'
            $length | Should -Not -BeNullOrEmpty

            $weight = Convert-Weight -Value 1000000 -FromUnit 'kg' -ToUnit 't'
            $weight | Should -Not -BeNullOrEmpty
        }
    }
}

