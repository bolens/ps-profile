

<#
.SYNOPSIS
    Integration tests for named color conversions.

.DESCRIPTION
    This test suite validates named color conversion functions including standard and extended named colors.

.NOTES
    Tests cover named color conversions and extended color name support.
#>

Describe 'Named Color Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Named Color Conversions' {
        It 'Converts RGB to closest named color' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'name'
            $result | Should -Be 'red'
        }

        It 'Converts HEX to closest named color' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'name'
            $result | Should -Be 'red'
        }

        It 'Converts exact named color to itself' {
            $result = Convert-Color -Color 'blue' -ToFormat 'name'
            $result | Should -Be 'blue'
        }

        It 'Converts white RGB to named color' {
            $result = Convert-Color -Color 'rgb(255, 255, 255)' -ToFormat 'name'
            $result | Should -Be 'white'
        }

        It 'Converts black RGB to named color' {
            $result = Convert-Color -Color 'rgb(0, 0, 0)' -ToFormat 'name'
            $result | Should -Be 'black'
        }
    }

    Context 'Extended Named Colors' {
        It 'Parses extended named color "rebeccapurple"' {
            $result = Parse-Color -Color 'rebeccapurple'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Parses extended named color "aliceblue"' {
            $result = Parse-Color -Color 'aliceblue'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Parses extended named color "transparent"' {
            $result = Parse-Color -Color 'transparent'
            $result.a | Should -Be 0
        }
    }

    Context 'Color function aliases' {
        It 'color-convert alias resolves to Convert-Color' {
            Get-Alias color-convert -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias color-convert).ResolvedCommandName | Should -Be 'Convert-Color'
        }

        It 'color-parse alias resolves to Parse-Color' {
            Get-Alias color-parse -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias color-parse).ResolvedCommandName | Should -Be 'Parse-Color'
        }
    }
}

