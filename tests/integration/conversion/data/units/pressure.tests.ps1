

<#
.SYNOPSIS
    Integration tests for Pressure unit conversion utilities.

.DESCRIPTION
    This test suite validates Pressure unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Pressure Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Pressure Conversions' {
        It 'Convert-Pressure function exists' {
            Get-Command Convert-Pressure -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Pressure converts pascals to psi' {
            $result = Convert-Pressure -Value 6894.76 -FromUnit 'pa' -ToUnit 'psi'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Pressure converts psi to pascals' {
            $result = Convert-Pressure -Value 1 -FromUnit 'psi' -ToUnit 'pa'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 6894
            $result.Value | Should -BeLessThan 6895
        }

        It 'Convert-Pressure converts bar to pascals' {
            $result = Convert-Pressure -Value 1 -FromUnit 'bar' -ToUnit 'pa'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 100000
        }

        It 'Convert-Pressure converts atmospheres to pascals' {
            $result = Convert-Pressure -Value 1 -FromUnit 'atm' -ToUnit 'pa'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 101325
        }

        It 'Convert-Pressure supports pipeline input' {
            $result = 100000 | Convert-Pressure -FromUnit 'pa' -ToUnit 'bar'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Pressure roundtrip conversion' {
            $original = 100000
            $converted = Convert-Pressure -Value $original -FromUnit 'pa' -ToUnit 'psi'
            $back = Convert-Pressure -Value $converted.Value -FromUnit 'psi' -ToUnit 'pa'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 1
        }

        It 'Convert-Pressure throws error for invalid unit' {
            { Convert-Pressure -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'pa' } | Should -Throw
        }
    }
}

