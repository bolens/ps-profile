

<#
.SYNOPSIS
    Integration tests for Fuel economy unit conversion utilities.

.DESCRIPTION
    This test suite validates Fuel economy unit conversion functions.

.NOTES
    Tests cover inverse units (mpg, L/100km, km/L) with special conversion handling.
#>

Describe 'Fuel Economy Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Fuel Economy Conversions' {
        It 'Convert-FuelEconomy function exists' {
            Get-Command Convert-FuelEconomy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-FuelEconomy converts mpg to L/100km' {
            $result = Convert-FuelEconomy -Value 30 -FromUnit 'mpg' -ToUnit 'l/100km'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 7.8405) | Should -BeLessThan 0.01
        }

        It 'Convert-FuelEconomy converts km/L to mpg' {
            $result = Convert-FuelEconomy -Value 15 -FromUnit 'km/l' -ToUnit 'mpg'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 35.282) | Should -BeLessThan 0.01
        }

        It 'Convert-FuelEconomy supports pipeline input' {
            $result = 25 | Convert-FuelEconomy -FromUnit 'mpg' -ToUnit 'l/100km'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 0
        }

        It 'Convert-FuelEconomy roundtrip conversion' {
            $original = 25
            $converted = Convert-FuelEconomy -Value $original -FromUnit 'mpg' -ToUnit 'l/100km'
            $back = Convert-FuelEconomy -Value $converted.Value -FromUnit 'l/100km' -ToUnit 'mpg'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.001
        }

        It 'Convert-FuelEconomy throws error for invalid unit' {
            { Convert-FuelEconomy -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'mpg' } | Should -Throw
        }

        It 'Convert-FuelEconomy throws error for zero mpg' {
            { Convert-FuelEconomy -Value 0 -FromUnit 'mpg' -ToUnit 'l/100km' } | Should -Throw
        }
    }
}
