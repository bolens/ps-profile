

<#
.SYNOPSIS
    Integration tests for Torque unit conversion utilities.

.DESCRIPTION
    This test suite validates Torque unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Torque Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Torque Conversions' {
        It 'Convert-Torque function exists' {
            Get-Command Convert-Torque -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Torque converts Nm to lb-ft' {
            $result = Convert-Torque -Value 1.35582 -FromUnit 'nm' -ToUnit 'lb-ft'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.001
        }

        It 'Convert-Torque converts lb-in to Nm' {
            $result = Convert-Torque -Value 10 -FromUnit 'lb-in' -ToUnit 'nm'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 1
        }

        It 'Convert-Torque supports pipeline input' {
            $result = 1 | Convert-Torque -FromUnit 'lb-ft' -ToUnit 'nm'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1.35582) | Should -BeLessThan 0.001
        }

        It 'Convert-Torque roundtrip conversion' {
            $original = 10
            $converted = Convert-Torque -Value $original -FromUnit 'lb-in' -ToUnit 'nm'
            $back = Convert-Torque -Value $converted.Value -FromUnit 'nm' -ToUnit 'lb-in'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.001
        }

        It 'Convert-Torque throws error for invalid unit' {
            { Convert-Torque -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'nm' } | Should -Throw
        }
    }
}
