

<#
.SYNOPSIS
    Integration tests for Volume unit conversion utilities.

.DESCRIPTION
    This test suite validates Volume unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Volume Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Volume Conversions' {
        It 'Convert-Volume function exists' {
            Get-Command Convert-Volume -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Volume converts liters to gallons' {
            $result = Convert-Volume -Value 3.78541 -FromUnit 'l' -ToUnit 'gal'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Volume converts gallons to liters' {
            $result = Convert-Volume -Value 1 -FromUnit 'gal' -ToUnit 'l'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 3.7
            $result.Value | Should -BeLessThan 3.8
        }

        It 'Convert-Volume converts milliliters to fluid ounces' {
            $result = Convert-Volume -Value 29.5735 -FromUnit 'ml' -ToUnit 'fl oz'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Volume supports pipeline input' {
            $result = 1000 | Convert-Volume -FromUnit 'ml' -ToUnit 'l'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Volume roundtrip conversion' {
            $original = 5
            $converted = Convert-Volume -Value $original -FromUnit 'l' -ToUnit 'gal'
            $back = Convert-Volume -Value $converted.Value -FromUnit 'gal' -ToUnit 'l'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.01
        }

        It 'Convert-Volume throws error for invalid unit' {
            { Convert-Volume -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'l' } | Should -Throw
        }
    }
}

