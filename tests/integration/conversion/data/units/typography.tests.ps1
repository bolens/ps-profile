

<#
.SYNOPSIS
    Integration tests for Typography unit conversion utilities.

.DESCRIPTION
    This test suite validates Typography and print unit conversion functions.

.NOTES
    Tests cover point, pica, pixel (with DPI), and physical length conversions.
#>

Describe 'Typography Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Typography Conversions' {
        It 'Convert-Typography function exists' {
            Get-Command Convert-Typography -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Typography converts 72 pt to 1 inch' {
            $result = Convert-Typography -Value 72 -FromUnit 'pt' -ToUnit 'in'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.001
        }

        It 'Convert-Typography converts 96 px to 1 inch at 96 DPI' {
            $result = Convert-Typography -Value 96 -FromUnit 'px' -ToUnit 'in' -Dpi 96
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.001
        }

        It 'Convert-Typography converts 12 pt to 1 pica' {
            $result = Convert-Typography -Value 12 -FromUnit 'pt' -ToUnit 'pc'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Typography supports pipeline input' {
            $result = 72 | Convert-Typography -FromUnit 'pt' -ToUnit 'in'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.001
        }

        It 'Convert-Typography roundtrip conversion' {
            $original = 16
            $converted = Convert-Typography -Value $original -FromUnit 'pt' -ToUnit 'mm'
            $back = Convert-Typography -Value $converted.Value -FromUnit 'mm' -ToUnit 'pt'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.001
        }

        It 'Convert-Typography throws error for invalid unit' {
            { Convert-Typography -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'pt' } | Should -Throw
        }

        It 'Convert-Typography throws error for invalid Dpi with pixels' {
            { Convert-Typography -Value 10 -FromUnit 'px' -ToUnit 'in' -Dpi 0 } | Should -Throw
        }
    }
}
