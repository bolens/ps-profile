

<#
.SYNOPSIS
    Integration tests for Density unit conversion utilities.

.DESCRIPTION
    This test suite validates Density unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Density Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Density Conversions' {
        It 'Convert-Density function exists' {
            Get-Command Convert-Density -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Density converts g/cm3 to kg/m3' {
            $result = Convert-Density -Value 1 -FromUnit 'g/cm3' -ToUnit 'kg/m3'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1000
        }

        It 'Convert-Density converts g/ml to g/cm3' {
            $result = Convert-Density -Value 1 -FromUnit 'g/ml' -ToUnit 'g/cm3'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Density supports pipeline input' {
            $result = 1000 | Convert-Density -FromUnit 'kg/m3' -ToUnit 'g/cm3'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Density roundtrip conversion' {
            $original = 2.5
            $converted = Convert-Density -Value $original -FromUnit 'g/cm3' -ToUnit 'kg/m3'
            $back = Convert-Density -Value $converted.Value -FromUnit 'kg/m3' -ToUnit 'g/cm3'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.001
        }

        It 'Convert-Density throws error for invalid unit' {
            { Convert-Density -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'kg/m3' } | Should -Throw
        }
    }
}
