

<#
.SYNOPSIS
    Integration tests for Area unit conversion utilities.

.DESCRIPTION
    This test suite validates Area unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Area Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Area Conversions' {
        It 'Convert-Area function exists' {
            Get-Command Convert-Area -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Area converts square meters to square feet' {
            $result = Convert-Area -Value 1 -FromUnit 'm2' -ToUnit 'ft2'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 10
            $result.Value | Should -BeLessThan 11
        }

        It 'Convert-Area converts square feet to square meters' {
            $result = Convert-Area -Value 10.7639 -FromUnit 'ft2' -ToUnit 'm2'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Area converts acres to square meters' {
            $result = Convert-Area -Value 1 -FromUnit 'acre' -ToUnit 'm2'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 4046
            $result.Value | Should -BeLessThan 4047
        }

        It 'Convert-Area converts hectares to acres' {
            $result = Convert-Area -Value 1 -FromUnit 'ha' -ToUnit 'acre'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 2.47
            $result.Value | Should -BeLessThan 2.48
        }

        It 'Convert-Area supports pipeline input' {
            $result = 10000 | Convert-Area -FromUnit 'm2' -ToUnit 'ha'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Area roundtrip conversion' {
            $original = 100
            $converted = Convert-Area -Value $original -FromUnit 'm2' -ToUnit 'ft2'
            $back = Convert-Area -Value $converted.Value -FromUnit 'ft2' -ToUnit 'm2'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.01
        }

        It 'Convert-Area throws error for invalid unit' {
            { Convert-Area -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'm2' } | Should -Throw
        }
    }
}

