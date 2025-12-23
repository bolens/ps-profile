

<#
.SYNOPSIS
    Integration tests for Weight/Mass unit conversion utilities.

.DESCRIPTION
    This test suite validates Weight/Mass unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Weight/Mass Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Weight/Mass Conversions' {
        It 'Convert-Weight function exists' {
            Get-Command Convert-Weight -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Weight converts kilograms to pounds' {
            $result = Convert-Weight -Value 1 -FromUnit 'kg' -ToUnit 'lb'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 2
            $result.Value | Should -BeLessThan 3
        }

        It 'Convert-Weight converts pounds to kilograms' {
            $result = Convert-Weight -Value 2.20462 -FromUnit 'lb' -ToUnit 'kg'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Weight converts grams to ounces' {
            $result = Convert-Weight -Value 28.3495 -FromUnit 'g' -ToUnit 'oz'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Weight supports pipeline input' {
            $result = 1000 | Convert-Weight -FromUnit 'g' -ToUnit 'kg'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Weight roundtrip conversion' {
            $original = 50
            $converted = Convert-Weight -Value $original -FromUnit 'kg' -ToUnit 'lb'
            $back = Convert-Weight -Value $converted.Value -FromUnit 'lb' -ToUnit 'kg'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.01
        }

        It 'Convert-Weight throws error for invalid unit' {
            { Convert-Weight -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'kg' } | Should -Throw
        }
    }
}

