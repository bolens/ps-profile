

<#
.SYNOPSIS
    Integration tests for Angle unit conversion utilities.

.DESCRIPTION
    This test suite validates Angle unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Angle Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Angle Conversions' {
        It 'Convert-Angle function exists' {
            Get-Command Convert-Angle -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Angle converts degrees to radians' {
            $result = Convert-Angle -Value 180 -FromUnit 'deg' -ToUnit 'rad'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - [math]::PI) | Should -BeLessThan 0.01
        }

        It 'Convert-Angle converts radians to degrees' {
            $result = Convert-Angle -Value [math]::PI -FromUnit 'rad' -ToUnit 'deg'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 180) | Should -BeLessThan 0.01
        }

        It 'Convert-Angle converts degrees to gradians' {
            $result = Convert-Angle -Value 90 -FromUnit 'deg' -ToUnit 'grad'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 100
        }

        It 'Convert-Angle converts gradians to degrees' {
            $result = Convert-Angle -Value 100 -FromUnit 'grad' -ToUnit 'deg'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 90
        }

        It 'Convert-Angle converts degrees to turns' {
            $result = Convert-Angle -Value 360 -FromUnit 'deg' -ToUnit 'turn'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Angle supports pipeline input' {
            $result = 90 | Convert-Angle -FromUnit 'deg' -ToUnit 'rad'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - ([math]::PI / 2)) | Should -BeLessThan 0.01
        }

        It 'Convert-Angle roundtrip conversion' {
            $original = 45
            $converted = Convert-Angle -Value $original -FromUnit 'deg' -ToUnit 'rad'
            $back = Convert-Angle -Value $converted.Value -FromUnit 'rad' -ToUnit 'deg'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.01
        }

        It 'Convert-Angle throws error for invalid unit' {
            { Convert-Angle -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'rad' } | Should -Throw
        }
    }
}

