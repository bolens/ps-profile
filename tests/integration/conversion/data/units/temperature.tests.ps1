

<#
.SYNOPSIS
    Integration tests for Temperature unit conversion utilities.

.DESCRIPTION
    This test suite validates Temperature unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Temperature Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Temperature Conversions' {
        It 'Convert-Temperature function exists' {
            Get-Command Convert-Temperature -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Temperature converts Celsius to Fahrenheit' {
            $result = Convert-Temperature -Value 0 -FromUnit 'C' -ToUnit 'F'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 32
        }

        It 'Convert-Temperature converts Fahrenheit to Celsius' {
            $result = Convert-Temperature -Value 32 -FromUnit 'F' -ToUnit 'C'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 0) | Should -BeLessThan 0.01
        }

        It 'Convert-Temperature converts Celsius to Kelvin' {
            $result = Convert-Temperature -Value 0 -FromUnit 'C' -ToUnit 'K'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 273.15) | Should -BeLessThan 0.01
        }

        It 'Convert-Temperature converts Kelvin to Celsius' {
            $result = Convert-Temperature -Value 273.15 -FromUnit 'K' -ToUnit 'C'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 0) | Should -BeLessThan 0.01
        }

        It 'Convert-Temperature converts Fahrenheit to Kelvin' {
            $result = Convert-Temperature -Value 32 -FromUnit 'F' -ToUnit 'K'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 273.15) | Should -BeLessThan 0.01
        }

        It 'Convert-Temperature supports pipeline input' {
            $result = 100 | Convert-Temperature -FromUnit 'C' -ToUnit 'F'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 212
        }

        It 'Convert-Temperature roundtrip conversion' {
            $original = 25
            $converted = Convert-Temperature -Value $original -FromUnit 'C' -ToUnit 'F'
            $back = Convert-Temperature -Value $converted.Value -FromUnit 'F' -ToUnit 'C'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.01
        }

        It 'Convert-Temperature throws error for invalid unit' {
            { Convert-Temperature -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'C' } | Should -Throw
        }
    }
}

