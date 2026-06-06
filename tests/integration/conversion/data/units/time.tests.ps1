

<#
.SYNOPSIS
    Integration tests for numeric time duration unit conversion utilities.

.DESCRIPTION
    This test suite validates Convert-Duration numeric time unit conversions.
    Distinct from data/time duration parsing tests (human-readable strings).

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Time Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Time Conversions' {
        It 'Convert-Duration function exists' {
            Get-Command Convert-Duration -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Duration converts seconds to hours' {
            $result = Convert-Duration -Value 3600 -FromUnit 's' -ToUnit 'h'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Duration converts nanoseconds to milliseconds' {
            $result = Convert-Duration -Value 1000000 -FromUnit 'ns' -ToUnit 'ms'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Duration converts fortnights to weeks' {
            $result = Convert-Duration -Value 1 -FromUnit 'fortnight' -ToUnit 'w'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 2
        }

        It 'Convert-Duration supports pipeline input' {
            $result = 3600 | Convert-Duration -FromUnit 's' -ToUnit 'h'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Duration roundtrip conversion' {
            $original = 86400
            $converted = Convert-Duration -Value $original -FromUnit 's' -ToUnit 'd'
            $back = Convert-Duration -Value $converted.Value -FromUnit 'd' -ToUnit 's'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.001
        }

        It 'Convert-Duration throws error for invalid unit' {
            { Convert-Duration -Value 1 -FromUnit 'InvalidUnit' -ToUnit 's' } | Should -Throw
        }
    }
}
