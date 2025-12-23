

<#
.SYNOPSIS
    Integration tests for HEX color format conversions.

.DESCRIPTION
    This test suite validates HEX color conversion functions.

.NOTES
    Tests cover HEX conversions including short form, long form, and alpha channels.
#>

Describe 'HEX Color Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'HEX Conversions' {
        It 'Converts RGB to HEX' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'hex'
            $result | Should -Be '#FF0000'
        }

        It 'Converts named color to HEX' {
            $result = Convert-Color -Color 'red' -ToFormat 'hex'
            $result | Should -Be '#FF0000'
        }

        It 'Converts HEX to HEX (identity)' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'hex'
            $result | Should -Be '#FF0000'
        }

        It 'Converts RGBA to HEX with alpha' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9A-F]{8}$'
        }

        It 'Converts HSL to HEX' {
            $result = Convert-Color -Color 'hsl(0, 100%, 50%)' -ToFormat 'hex'
            $result | Should -Be '#FF0000'
        }

        It 'Converts HWB to HEX' {
            $result = Convert-Color -Color 'hwb(0, 0%, 0%)' -ToFormat 'hex'
            $result | Should -Be '#FF0000'
        }

        It 'Converts CMYK to HEX' {
            $result = Convert-Color -Color 'cmyk(0%, 100%, 100%, 0%)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9A-F]{6}$'
        }

        It 'Converts LAB to HEX' {
            $result = Convert-Color -Color 'lab(53.24 80.09 67.20)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9a-fA-F]{6}$'
        }

        It 'Converts OKLAB to HEX' {
            $result = Convert-Color -Color 'oklab(0.62796 0.22486 0.12585)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9a-fA-F]{6}$'
        }

        It 'Converts LCH to HEX' {
            $result = Convert-Color -Color 'lch(53.24 104.55 40.85)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9a-fA-F]{6}$'
        }

        It 'Converts OKLCH to HEX' {
            $result = Convert-Color -Color 'oklch(0.62796 0.22486 0.12585)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9a-fA-F]{6}$'
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

