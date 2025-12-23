

<#
.SYNOPSIS
    Integration tests for Speed unit conversion utilities.

.DESCRIPTION
    This test suite validates Speed unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Speed Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Speed Conversions' {
        It 'Convert-Speed function exists' {
            Get-Command Convert-Speed -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Speed converts m/s to km/h' {
            $result = Convert-Speed -Value 1 -FromUnit 'm/s' -ToUnit 'km/h'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 3.6
        }

        It 'Convert-Speed converts km/h to mph' {
            $result = Convert-Speed -Value 100 -FromUnit 'km/h' -ToUnit 'mph'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 62
            $result.Value | Should -BeLessThan 63
        }

        It 'Convert-Speed converts mph to m/s' {
            $result = Convert-Speed -Value 60 -FromUnit 'mph' -ToUnit 'm/s'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 26
            $result.Value | Should -BeLessThan 27
        }

        It 'Convert-Speed converts knots to km/h' {
            $result = Convert-Speed -Value 1 -FromUnit 'knot' -ToUnit 'km/h'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 1.8
            $result.Value | Should -BeLessThan 1.9
        }

        It 'Convert-Speed supports pipeline input' {
            $result = 10 | Convert-Speed -FromUnit 'm/s' -ToUnit 'km/h'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 36
        }

        It 'Convert-Speed roundtrip conversion' {
            $original = 50
            $converted = Convert-Speed -Value $original -FromUnit 'km/h' -ToUnit 'mph'
            $back = Convert-Speed -Value $converted.Value -FromUnit 'mph' -ToUnit 'km/h'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.01
        }

        It 'Convert-Speed throws error for invalid unit' {
            { Convert-Speed -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'm/s' } | Should -Throw
        }
    }
}

