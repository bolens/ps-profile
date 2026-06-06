

<#
.SYNOPSIS
    Integration tests for Force unit conversion utilities.

.DESCRIPTION
    This test suite validates Force unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Force Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Force Conversions' {
        It 'Convert-Force function exists' {
            Get-Command Convert-Force -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Force converts newtons to pound-force' {
            $result = Convert-Force -Value 4.44822 -FromUnit 'n' -ToUnit 'lbf'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.001
        }

        It 'Convert-Force converts kilogram-force to newtons' {
            $result = Convert-Force -Value 1 -FromUnit 'kgf' -ToUnit 'n'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 9.80665) | Should -BeLessThan 0.0001
        }

        It 'Convert-Force supports pipeline input' {
            $result = 10 | Convert-Force -FromUnit 'n' -ToUnit 'lbf'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 2
        }

        It 'Convert-Force roundtrip conversion' {
            $original = 100
            $converted = Convert-Force -Value $original -FromUnit 'n' -ToUnit 'lbf'
            $back = Convert-Force -Value $converted.Value -FromUnit 'lbf' -ToUnit 'n'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.01
        }

        It 'Convert-Force throws error for invalid unit' {
            { Convert-Force -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'n' } | Should -Throw
        }
    }
}
