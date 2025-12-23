

<#
.SYNOPSIS
    Integration tests for color roundtrip conversions and pipeline support.

.DESCRIPTION
    This test suite validates roundtrip color conversions and pipeline functionality.

.NOTES
    Tests cover roundtrip conversions between various color formats and pipeline support.
#>

Describe 'Color Roundtrip and Pipeline Support Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Roundtrip Conversions' {
        It 'Roundtrips HEX -> RGB -> HEX' {
            $original = '#ff0000'
            $rgb = Convert-Color -Color $original -ToFormat 'rgb'
            $hex = Convert-Color -Color $rgb -ToFormat 'hex'
            $hex | Should -Be '#FF0000'
        }

        It 'Roundtrips RGB -> HSL -> RGB' {
            $original = 'rgb(255, 0, 0)'
            $hsl = Convert-Color -Color $original -ToFormat 'hsl'
            $rgb = Convert-Color -Color $hsl -ToFormat 'rgb'
            $rgb | Should -Match '^rgb\(255,\s*0,\s*0\)$'
        }

        It 'Roundtrips HEX -> HSL -> HEX' {
            $original = '#00ff00'
            $hsl = Convert-Color -Color $original -ToFormat 'hsl'
            $hex = Convert-Color -Color $hsl -ToFormat 'hex'
            $hex | Should -Be '#00FF00'
        }

        It 'Roundtrips RGB -> HWB -> RGB' {
            $original = 'rgb(255, 0, 0)'
            $hwb = Convert-Color -Color $original -ToFormat 'hwb'
            $rgb = Convert-Color -Color $hwb -ToFormat 'rgb'
            $rgb | Should -Match '^rgb\(255,\s*0,\s*0\)$'
        }

        It 'Roundtrips RGB -> CMYK -> RGB' {
            $original = 'rgb(255, 0, 0)'
            $cmyk = Convert-Color -Color $original -ToFormat 'cmyk'
            $rgb = Convert-Color -Color $cmyk -ToFormat 'rgb'
            $rgb | Should -Match '^rgb\(255,\s*0,\s*0\)$'
        }

        It 'Roundtrips RGBA -> HSLA -> RGBA' {
            $original = 'rgba(255, 0, 0, 0.5)'
            $hsla = Convert-Color -Color $original -ToFormat 'hsla'
            $rgba = Convert-Color -Color $hsla -ToFormat 'rgba'
            $rgba | Should -Match 'rgba\(255,\s*0,\s*0,\s*0\.5\)'
        }
    }

    Context 'Pipeline Support' {
        It 'Accepts color from pipeline' {
            $result = '#ff0000' | Convert-Color -ToFormat 'rgb'
            $result | Should -Match '^rgb\(255,\s*0,\s*0\)$'
        }

        It 'Accepts color from pipeline for Parse-Color' {
            $result = '#ff0000' | Parse-Color
            $result.r | Should -Be 255
            $result.g | Should -Be 0
            $result.b | Should -Be 0
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

