

<#
.SYNOPSIS
    Integration tests for color parsing utilities.

.DESCRIPTION
    This test suite validates color parsing functions and edge cases.

.NOTES
    Tests cover color parsing, edge cases, and format validation.
#>

Describe 'Color Parsing Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Color Parsing' {
        It 'Parses HEX color #ff0000' {
            $result = Parse-Color -Color '#ff0000'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Parses short HEX color #f00' {
            $result = Parse-Color -Color '#f00'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Parses HEX color with alpha #ff000080' {
            $result = Parse-Color -Color '#ff000080'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
            $result.a | Should -BeGreaterThan 0
            $result.a | Should -BeLessThan 1
        }

        It 'Parses RGB color' {
            $result = Parse-Color -Color 'rgb(255, 0, 0)'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Parses RGBA color' {
            $result = Parse-Color -Color 'rgba(255, 0, 0, 0.5)'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
            $result.a | Should -Be 0.5
        }

        It 'Parses RGB color with percentages' {
            $result = Parse-Color -Color 'rgb(100%, 0%, 0%)'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Parses HSL color' {
            $result = Parse-Color -Color 'hsl(0, 100%, 50%)'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Parses HSLA color' {
            $result = Parse-Color -Color 'hsla(0, 100%, 50%, 0.5)'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
            $result.a | Should -Be 0.5
        }

        It 'Parses HWB color' {
            $result = Parse-Color -Color 'hwb(0, 0%, 0%)'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Parses HWBA color' {
            $result = Parse-Color -Color 'hwba(0, 0%, 0%, 0.5)'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
            $result.a | Should -Be 0.5
        }

        It 'Parses CMYK color' {
            $result = Parse-Color -Color 'cmyk(0%, 100%, 100%, 0%)'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Parses CMYKA color' {
            $result = Parse-Color -Color 'cmyka(0%, 100%, 100%, 0%, 0.5)'
            $result | Should -Not -BeNullOrEmpty
            $result.a | Should -Be 0.5
        }

        It 'Parses NCOL color' {
            $result = Parse-Color -Color 'ncol(R, 0%, 0%)'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Parses NCOLA color' {
            $result = Parse-Color -Color 'ncola(R, 0%, 0%, 0.5)'
            $result | Should -Not -BeNullOrEmpty
            $result.a | Should -Be 0.5
        }

        It 'Parses named color' {
            $result = Parse-Color -Color 'red'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Accepts color from pipeline for Parse-Color' {
            $result = '#ff0000' | Parse-Color
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }
    }

    Context 'Edge Cases' {
        It 'Handles color values at boundaries (0, 255)' {
            $result = Parse-Color -Color 'rgb(0, 0, 0)'
            $result.r | Should -Be 0
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Handles color values at boundaries (255, 255, 255)' {
            $result = Parse-Color -Color 'rgb(255, 255, 255)'
            $result.r | Should -Be 255
            $result.g | Should -Be 255
            $result.b | Should -Be 255
        }

        It 'Clamps RGB values above 255' {
            $result = Parse-Color -Color 'rgb(300, 300, 300)'
            $result.r | Should -Be 255
            $result.g | Should -Be 255
            $result.b | Should -Be 255
        }

        It 'Clamps RGB values below 0' {
            $result = Parse-Color -Color 'rgb(-10, -10, -10)'
            $result.r | Should -Be 0
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Handles alpha value at 0' {
            $result = Parse-Color -Color 'rgba(255, 0, 0, 0)'
            $result.a | Should -Be 0
        }

        It 'Handles alpha value at 1' {
            $result = Parse-Color -Color 'rgba(255, 0, 0, 1)'
            $result.a | Should -Be 1
        }

        It 'Clamps alpha value above 1' {
            $result = Parse-Color -Color 'rgba(255, 0, 0, 1.5)'
            $result.a | Should -Be 1
        }

        It 'Clamps alpha value below 0' {
            $result = Parse-Color -Color 'rgba(255, 0, 0, -0.5)'
            $result.a | Should -Be 0
        }

        It 'Handles HSL hue wrapping (360+ degrees)' {
            $result = Parse-Color -Color 'hsl(360, 100%, 50%)'
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Handles HSL hue wrapping (negative degrees)' {
            $result = Parse-Color -Color 'hsl(-30, 100%, 50%)'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles HSL saturation at 0% (grayscale)' {
            $result = Parse-Color -Color 'hsl(0, 0%, 50%)'
            $result.r | Should -Be $result.g
            $result.g | Should -Be $result.b
        }

        It 'Handles HSL lightness at 0% (black)' {
            $result = Parse-Color -Color 'hsl(0, 100%, 0%)'
            $result.r | Should -Be 0
            $result.g | Should -Be 0
            $result.b | Should -Be 0
        }

        It 'Handles HSL lightness at 100% (white)' {
            $result = Parse-Color -Color 'hsl(0, 100%, 100%)'
            $result.r | Should -Be 255
            $result.g | Should -Be 255
            $result.b | Should -Be 255
        }
    }

    Context 'Color Format Validation' {
        It 'Rejects invalid ToFormat parameter' {
            { Convert-Color -Color '#ff0000' -ToFormat 'invalid' } | Should -Throw
        }

        It 'Rejects invalid color format' {
            { Parse-Color -Color 'not-a-color' } | Should -Throw
        }

        It 'Rejects empty color string' {
            { Parse-Color -Color '' } | Should -Throw
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

