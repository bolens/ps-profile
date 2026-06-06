

<#
.SYNOPSIS
    Integration tests for unit conversion edge cases and error handling.

.DESCRIPTION
    This test suite validates edge cases and error handling across all unit conversion functions.

.NOTES
    Tests cover zero values, negative values, and very large values across unit types.
#>

Describe 'Unit Conversion Edge Cases and Error Handling Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Edge Cases and Error Handling' {
        It 'Core unit conversion functions handle zero values' {
            $length = Convert-Length -Value 0 -FromUnit 'm' -ToUnit 'ft'
            $length.Value | Should -Be 0

            $weight = Convert-Weight -Value 0 -FromUnit 'kg' -ToUnit 'lb'
            $weight.Value | Should -Be 0

            $temp = Convert-Temperature -Value 0 -FromUnit 'C' -ToUnit 'F'
            $temp.Value | Should -Be 32

            $volume = Convert-Volume -Value 0 -FromUnit 'l' -ToUnit 'gal'
            $volume.Value | Should -Be 0
        }

        It 'Extended unit conversion functions handle zero values' {
            $power = Convert-Power -Value 0 -FromUnit 'w' -ToUnit 'hp'
            $power.Value | Should -Be 0

            $duration = Convert-Duration -Value 0 -FromUnit 's' -ToUnit 'h'
            $duration.Value | Should -Be 0

            $density = Convert-Density -Value 0 -FromUnit 'g/cm3' -ToUnit 'kg/m3'
            $density.Value | Should -Be 0

            $dataRate = Convert-DataRate -Value 0 -FromUnit 'mbps' -ToUnit 'kbps'
            $dataRate.Value | Should -Be 0
        }

        It 'Unit conversion functions handle negative values' {
            $length = Convert-Length -Value -10 -FromUnit 'm' -ToUnit 'ft'
            $length.Value | Should -BeLessThan 0

            $temp = Convert-Temperature -Value -10 -FromUnit 'C' -ToUnit 'F'
            $temp.Value | Should -BeLessThan 32

            $force = Convert-Force -Value -5 -FromUnit 'n' -ToUnit 'lbf'
            $force.Value | Should -BeLessThan 0
        }

        It 'Unit conversion functions handle very large values' {
            $length = Convert-Length -Value 1000000 -FromUnit 'km' -ToUnit 'mi'
            $length | Should -Not -BeNullOrEmpty

            $weight = Convert-Weight -Value 1000000 -FromUnit 'kg' -ToUnit 't'
            $weight | Should -Not -BeNullOrEmpty

            $frequency = Convert-Frequency -Value 1000000 -FromUnit 'hz' -ToUnit 'mhz'
            $frequency | Should -Not -BeNullOrEmpty
            $frequency.Value | Should -Be 1
        }
    }
}
