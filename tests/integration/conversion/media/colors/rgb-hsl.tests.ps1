

<#
.SYNOPSIS
    Integration tests for RGB, RGBA, HSL, HSLA, and advanced color space conversions.

.DESCRIPTION
    This test suite validates RGB, RGBA, HSL, HSLA, LAB, OKLAB, LCH, and OKLCH color conversion functions.

.NOTES
    Tests cover bidirectional conversions and advanced color spaces.
#>

Describe 'RGB, HSL, and Advanced Color Space Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'RGB Conversions' {
        It 'Converts HEX to RGB' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'rgb'
            $result | Should -Match '^rgb\(255,\s*0,\s*0\)$'
        }

        It 'Converts named color to RGB' {
            $result = Convert-Color -Color 'red' -ToFormat 'rgb'
            $result | Should -Match '^rgb\(255,\s*0,\s*0\)$'
        }

        It 'Converts HSL to RGB' {
            $result = Convert-Color -Color 'hsl(0, 100%, 50%)' -ToFormat 'rgb'
            $result | Should -Match '^rgb\(255,\s*0,\s*0\)$'
        }

        It 'Converts HWB to RGB' {
            $result = Convert-Color -Color 'hwb(0, 0%, 0%)' -ToFormat 'rgb'
            $result | Should -Match '^rgb\(255,\s*0,\s*0\)$'
        }
    }

    Context 'RGBA Conversions' {
        It 'Converts HEX with alpha to RGBA' {
            $result = Convert-Color -Color '#ff000080' -ToFormat 'rgba'
            $result | Should -Match 'rgba\(255,\s*0,\s*0,\s*'
        }

        It 'Converts RGB to RGBA (defaults alpha to 1.0)' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'rgba'
            $result | Should -Match 'rgba\(255,\s*0,\s*0,\s*1(?:\.0)?\)$'
        }
    }

    Context 'HSL Conversions' {
        It 'Converts RGB to HSL' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'hsl'
            $result | Should -Match '^hsl\(0(?:\.0)?,\s*100(?:\.0)?%,\s*50(?:\.0)?%\)$'
        }

        It 'Converts HEX to HSL' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'hsl'
            $result | Should -Match '^hsl\(0(?:\.0)?,\s*100(?:\.0)?%,\s*50(?:\.0)?%\)$'
        }

        It 'Converts named color to HSL' {
            $result = Convert-Color -Color 'red' -ToFormat 'hsl'
            $result | Should -Match '^hsl\(0(?:\.0)?,\s*100(?:\.0)?%,\s*50(?:\.0)?%\)$'
        }

        It 'Converts HSL to HSL (identity)' {
            $result = Convert-Color -Color 'hsl(0, 100%, 50%)' -ToFormat 'hsl'
            $result | Should -Match '^hsl\(0(?:\.0)?,\s*100(?:\.0)?%,\s*50(?:\.0)?%\)$'
        }

        It 'Converts green RGB to HSL' {
            $result = Convert-Color -Color 'rgb(0, 255, 0)' -ToFormat 'hsl'
            $result | Should -Match '^hsl\(120(?:\.0)?,\s*100(?:\.0)?%,\s*50(?:\.0)?%\)$'
        }

        It 'Converts blue RGB to HSL' {
            $result = Convert-Color -Color 'rgb(0, 0, 255)' -ToFormat 'hsl'
            $result | Should -Match '^hsl\(240(?:\.0)?,\s*100(?:\.0)?%,\s*50(?:\.0)?%\)$'
        }
    }

    Context 'HSLA Conversions' {
        It 'Converts RGBA to HSLA' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'hsla'
            $result | Should -Match 'hsla\(0(?:\.0)?,\s*100(?:\.0)?%,\s*50(?:\.0)?%,\s*0\.5\)$'
        }

        It 'Converts RGB to HSLA (defaults alpha to 1.0)' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'hsla'
            $result | Should -Match 'hsla\(0(?:\.0)?,\s*100(?:\.0)?%,\s*50(?:\.0)?%,\s*1(?:\.0)?\)$'
        }
    }

    Context 'LAB Conversions' {
        It 'Parses LAB color' {
            $result = Parse-Color -Color 'lab(53.24 80.09 67.20)'
            $result | Should -Not -BeNullOrEmpty
            $result.r | Should -BeGreaterOrEqual 0
            $result.g | Should -BeGreaterOrEqual 0
            $result.b | Should -BeGreaterOrEqual 0
        }

        It 'Converts RGB to LAB' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'lab'
            $result | Should -Match '^lab\([\d.]+\s+[\d.]+\s+[\d.]+\)$'
        }

        It 'Converts HEX to LAB' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'lab'
            $result | Should -Match '^lab\([\d.]+\s+[\d.]+\s+[\d.]+\)$'
        }

        It 'Converts LAB to RGB' {
            $result = Convert-Color -Color 'lab(53.24 80.09 67.20)' -ToFormat 'rgb'
            $result | Should -Match '^rgb\([\d]+,\s*[\d]+,\s*[\d]+\)$'
        }

        It 'Converts LAB to HEX' {
            $result = Convert-Color -Color 'lab(53.24 80.09 67.20)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9a-fA-F]{6}$'
        }
    }

    Context 'LABa Conversions' {
        It 'Parses LABa color with alpha' {
            $result = Parse-Color -Color 'laba(53.24 80.09 67.20 / 0.5)'
            $result | Should -Not -BeNullOrEmpty
            $result.a | Should -Be 0.5
        }

        It 'Converts RGBA to LABa' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'laba'
            $result | Should -Match 'laba\([\d.]+\s+[\d.]+\s+[\d.]+\s+/\s+0\.5\)$'
        }

        It 'Converts RGB to LABa (defaults alpha to 1.0)' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'laba'
            $result | Should -Match 'laba\([\d.]+\s+[\d.]+\s+[\d.]+\s+/\s+1(?:\.0)?\)$'
        }
    }

    Context 'OKLAB Conversions' {
        It 'Parses OKLAB color' {
            $result = Parse-Color -Color 'oklab(0.62796 0.22486 0.12585)'
            $result | Should -Not -BeNullOrEmpty
            $result.r | Should -BeGreaterOrEqual 0
            $result.g | Should -BeGreaterOrEqual 0
            $result.b | Should -BeGreaterOrEqual 0
        }

        It 'Converts RGB to OKLAB' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'oklab'
            $result | Should -Match '^oklab\([\d.]+\s+[\d.]+\s+[\d.]+\)$'
        }

        It 'Converts HEX to OKLAB' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'oklab'
            $result | Should -Match '^oklab\([\d.]+\s+[\d.]+\s+[\d.]+\)$'
        }

        It 'Converts OKLAB to RGB' {
            $result = Convert-Color -Color 'oklab(0.62796 0.22486 0.12585)' -ToFormat 'rgb'
            $result | Should -Match '^rgb\([\d]+,\s*[\d]+,\s*[\d]+\)$'
        }

        It 'Converts OKLAB to HEX' {
            $result = Convert-Color -Color 'oklab(0.62796 0.22486 0.12585)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9a-fA-F]{6}$'
        }
    }

    Context 'OKLABa Conversions' {
        It 'Parses OKLABa color with alpha' {
            $result = Parse-Color -Color 'oklaba(0.62796 0.22486 0.12585 / 0.5)'
            $result | Should -Not -BeNullOrEmpty
            $result.a | Should -Be 0.5
        }

        It 'Converts RGBA to OKLABa' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'oklaba'
            $result | Should -Match 'oklaba\([\d.]+\s+[\d.]+\s+[\d.]+\s+/\s+0\.5\)$'
        }

        It 'Converts RGB to OKLABa (defaults alpha to 1.0)' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'oklaba'
            $result | Should -Match 'oklaba\([\d.]+\s+[\d.]+\s+[\d.]+\s+/\s+1(?:\.0)?\)$'
        }
    }

    Context 'LCH Conversions' {
        It 'Parses LCH color' {
            $result = Parse-Color -Color 'lch(53.24 104.55 40.85)'
            $result | Should -Not -BeNullOrEmpty
            $result.r | Should -BeGreaterOrEqual 0
            $result.g | Should -BeGreaterOrEqual 0
            $result.b | Should -BeGreaterOrEqual 0
        }

        It 'Converts RGB to LCH' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'lch'
            $result | Should -Match '^lch\([\d.]+\s+[\d.]+\s+[\d.]+\)$'
        }

        It 'Converts HEX to LCH' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'lch'
            $result | Should -Match '^lch\([\d.]+\s+[\d.]+\s+[\d.]+\)$'
        }

        It 'Converts LCH to RGB' {
            $result = Convert-Color -Color 'lch(53.24 104.55 40.85)' -ToFormat 'rgb'
            $result | Should -Match '^rgb\([\d]+,\s*[\d]+,\s*[\d]+\)$'
        }

        It 'Converts LCH to HEX' {
            $result = Convert-Color -Color 'lch(53.24 104.55 40.85)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9a-fA-F]{6}$'
        }
    }

    Context 'LCHa Conversions' {
        It 'Parses LCHa color with alpha' {
            $result = Parse-Color -Color 'lcha(53.24 104.55 40.85 / 0.5)'
            $result | Should -Not -BeNullOrEmpty
            $result.a | Should -Be 0.5
        }

        It 'Converts RGBA to LCHa' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'lcha'
            $result | Should -Match 'lcha\([\d.]+\s+[\d.]+\s+[\d.]+\s+/\s+0\.5\)$'
        }

        It 'Converts RGB to LCHa (defaults alpha to 1.0)' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'lcha'
            $result | Should -Match 'lcha\([\d.]+\s+[\d.]+\s+[\d.]+\s+/\s+1(?:\.0)?\)$'
        }
    }

    Context 'OKLCH Conversions' {
        It 'Parses OKLCH color' {
            $result = Parse-Color -Color 'oklch(0.62796 0.25768 29.2339)'
            $result | Should -Not -BeNullOrEmpty
            $result.r | Should -BeGreaterOrEqual 0
            $result.g | Should -BeGreaterOrEqual 0
            $result.b | Should -BeGreaterOrEqual 0
        }

        It 'Converts RGB to OKLCH' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'oklch'
            $result | Should -Match '^oklch\([\d.]+\s+[\d.]+\s+[\d.]+\)$'
        }

        It 'Converts HEX to OKLCH' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'oklch'
            $result | Should -Match '^oklch\([\d.]+\s+[\d.]+\s+[\d.]+\)$'
        }

        It 'Converts OKLCH to RGB' {
            $result = Convert-Color -Color 'oklch(0.62796 0.25768 29.2339)' -ToFormat 'rgb'
            $result | Should -Match '^rgb\([\d]+,\s*[\d]+,\s*[\d]+\)$'
        }

        It 'Converts OKLCH to HEX' {
            $result = Convert-Color -Color 'oklch(0.62796 0.25768 29.2339)' -ToFormat 'hex'
            $result | Should -Match '^#[0-9a-fA-F]{6}$'
        }
    }

    Context 'OKLCHa Conversions' {
        It 'Parses OKLCHa color with alpha' {
            $result = Parse-Color -Color 'oklcha(0.62796 0.25768 29.2339 / 0.5)'
            $result | Should -Not -BeNullOrEmpty
            $result.a | Should -Be 0.5
        }

        It 'Converts RGBA to OKLCHa' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'oklcha'
            $result | Should -Match 'oklcha\([\d.]+\s+[\d.]+\s+[\d.]+\s+/\s+0\.5\)$'
        }

        It 'Converts RGB to OKLCHa (defaults alpha to 1.0)' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'oklcha'
            $result | Should -Match 'oklcha\([\d.]+\s+[\d.]+\s+[\d.]+\s+/\s+1(?:\.0)?\)$'
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

