

<#
.SYNOPSIS
    Integration tests for Acceleration unit conversion utilities.

.DESCRIPTION
    This test suite validates Acceleration unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Acceleration Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Acceleration Conversions' {
        It 'Convert-Acceleration function exists' {
            Get-Command Convert-Acceleration -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Acceleration converts g to m/s2' {
            $result = Convert-Acceleration -Value 1 -FromUnit 'g' -ToUnit 'm/s2'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 9.80665) | Should -BeLessThan 0.0001
        }

        It 'Convert-Acceleration converts ft/s2 to m/s2' {
            $result = Convert-Acceleration -Value 1 -FromUnit 'ft/s2' -ToUnit 'm/s2'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 0.3048) | Should -BeLessThan 0.0001
        }

        It 'Convert-Acceleration supports pipeline input' {
            $result = 9.80665 | Convert-Acceleration -FromUnit 'm/s2' -ToUnit 'g'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.0001
        }

        It 'Convert-Acceleration roundtrip conversion' {
            $original = 5
            $converted = Convert-Acceleration -Value $original -FromUnit 'g' -ToUnit 'm/s2'
            $back = Convert-Acceleration -Value $converted.Value -FromUnit 'm/s2' -ToUnit 'g'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.0001
        }

        It 'Convert-Acceleration throws error for invalid unit' {
            { Convert-Acceleration -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'm/s2' } | Should -Throw
        }
    }
}
