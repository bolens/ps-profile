

<#
.SYNOPSIS
    Integration tests for Power unit conversion utilities.

.DESCRIPTION
    This test suite validates Power unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Power Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Power Conversions' {
        It 'Convert-Power function exists' {
            Get-Command Convert-Power -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Power converts watts to horsepower' {
            $result = Convert-Power -Value 745.7 -FromUnit 'w' -ToUnit 'hp'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Power converts kilowatts to watts' {
            $result = Convert-Power -Value 2 -FromUnit 'kw' -ToUnit 'w'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 2000
        }

        It 'Convert-Power supports pipeline input' {
            $result = 1000 | Convert-Power -FromUnit 'w' -ToUnit 'kw'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Power roundtrip conversion' {
            $original = 100
            $converted = Convert-Power -Value $original -FromUnit 'w' -ToUnit 'hp'
            $back = Convert-Power -Value $converted.Value -FromUnit 'hp' -ToUnit 'w'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.1
        }

        It 'Convert-Power throws error for invalid unit' {
            { Convert-Power -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'w' } | Should -Throw
        }
    }
}
