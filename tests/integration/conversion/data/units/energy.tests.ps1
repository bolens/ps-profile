

<#
.SYNOPSIS
    Integration tests for Energy unit conversion utilities.

.DESCRIPTION
    This test suite validates Energy unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Energy Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Energy Conversions' {
        It 'Convert-Energy function exists' {
            Get-Command Convert-Energy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Energy converts joules to calories' {
            $result = Convert-Energy -Value 4.184 -FromUnit 'j' -ToUnit 'cal'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Energy converts calories to joules' {
            $result = Convert-Energy -Value 1 -FromUnit 'cal' -ToUnit 'j'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 4.184) | Should -BeLessThan 0.01
        }

        It 'Convert-Energy converts kilowatt-hours to joules' {
            $result = Convert-Energy -Value 1 -FromUnit 'kwh' -ToUnit 'j'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 3600000
        }

        It 'Convert-Energy converts BTUs to joules' {
            $result = Convert-Energy -Value 1 -FromUnit 'btu' -ToUnit 'j'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 1055
            $result.Value | Should -BeLessThan 1056
        }

        It 'Convert-Energy supports pipeline input' {
            $result = 1000 | Convert-Energy -FromUnit 'j' -ToUnit 'kj'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Energy roundtrip conversion' {
            $original = 1000
            $converted = Convert-Energy -Value $original -FromUnit 'j' -ToUnit 'cal'
            $back = Convert-Energy -Value $converted.Value -FromUnit 'cal' -ToUnit 'j'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.1
        }

        It 'Convert-Energy throws error for invalid unit' {
            { Convert-Energy -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'j' } | Should -Throw
        }
    }
}

