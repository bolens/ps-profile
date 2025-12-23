

<#
.SYNOPSIS
    Integration tests for Length unit conversion utilities.

.DESCRIPTION
    This test suite validates Length unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Length Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Length Conversions' {
        It 'Convert-Length function exists' {
            Get-Command Convert-Length -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-Length converts meters to feet' {
            $result = Convert-Length -Value 1 -FromUnit 'm' -ToUnit 'ft'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 3
            $result.Value | Should -BeLessThan 4
            $result.Unit | Should -Be 'ft'
        }

        It 'Convert-Length converts feet to meters' {
            $result = Convert-Length -Value 3.28084 -FromUnit 'ft' -ToUnit 'm'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.01
        }

        It 'Convert-Length converts kilometers to miles' {
            $result = Convert-Length -Value 1 -FromUnit 'km' -ToUnit 'mi'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -BeGreaterThan 0.6
            $result.Value | Should -BeLessThan 0.7
        }

        It 'Convert-Length supports pipeline input' {
            $result = 1000 | Convert-Length -FromUnit 'm' -ToUnit 'km'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
        }

        It 'Convert-Length supports plural unit names' {
            $result = Convert-Length -Value 1 -FromUnit 'kilometers' -ToUnit 'miles'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Convert-Length roundtrip conversion' {
            $original = 100
            $converted = Convert-Length -Value $original -FromUnit 'm' -ToUnit 'ft'
            $back = Convert-Length -Value $converted.Value -FromUnit 'ft' -ToUnit 'm'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.01
        }

        It 'Convert-Length throws error for invalid unit' {
            { Convert-Length -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'm' } | Should -Throw
        }
    }
}

