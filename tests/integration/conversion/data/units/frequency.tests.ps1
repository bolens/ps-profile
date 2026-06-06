

<#
.SYNOPSIS
    Integration tests for Frequency unit conversion utilities.

.DESCRIPTION
    This test suite validates Frequency and rotational speed conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Frequency Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Frequency Conversions' {
        It 'Convert-Frequency function exists' {
            Get-Command Convert-Frequency -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Frequency converts Hz to kHz' {
            $result = Convert-Frequency -Value 1000 -FromUnit 'hz' -ToUnit 'khz'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Frequency converts rpm to Hz' {
            $result = Convert-Frequency -Value 60 -FromUnit 'rpm' -ToUnit 'hz'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.0001
        }

        It 'Convert-Frequency converts Hz to rad/s' {
            $result = Convert-Frequency -Value 1 -FromUnit 'hz' -ToUnit 'rad/s'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 6.283185307) | Should -BeLessThan 0.001
        }

        It 'Convert-Frequency supports pipeline input' {
            $result = 1000 | Convert-Frequency -FromUnit 'hz' -ToUnit 'khz'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Frequency roundtrip conversion' {
            $original = 60
            $converted = Convert-Frequency -Value $original -FromUnit 'rpm' -ToUnit 'hz'
            $back = Convert-Frequency -Value $converted.Value -FromUnit 'hz' -ToUnit 'rpm'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.001
        }

        It 'Convert-Frequency throws error for invalid unit' {
            { Convert-Frequency -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'hz' } | Should -Throw
        }
    }
}
