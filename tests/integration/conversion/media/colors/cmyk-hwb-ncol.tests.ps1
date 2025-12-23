

<#
.SYNOPSIS
    Integration tests for CMYK, HWB, and NCOL color format conversions.

.DESCRIPTION
    This test suite validates CMYK, CMYKA, HWB, HWBA, NCOL, and NCOLA color conversion functions.

.NOTES
    Tests cover bidirectional conversions and edge cases.
#>

Describe 'CMYK, HWB, and NCOL Color Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'HWB Conversions' {
        It 'Converts RGB to HWB' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'hwb'
            $result | Should -Match '^hwb\(0(?:\.0)?,\s*0(?:\.0)?%,\s*0(?:\.0)?%\)$'
        }

        It 'Converts HEX to HWB' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'hwb'
            $result | Should -Match '^hwb\(0(?:\.0)?,\s*0(?:\.0)?%,\s*0(?:\.0)?%\)$'
        }

        It 'Converts HSL to HWB' {
            $result = Convert-Color -Color 'hsl(0, 100%, 50%)' -ToFormat 'hwb'
            $result | Should -Match '^hwb\(0(?:\.0)?,\s*0(?:\.0)?%,\s*0(?:\.0)?%\)$'
        }
    }

    Context 'HWBA Conversions' {
        It 'Converts RGBA to HWBA' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'hwba'
            $result | Should -Match 'hwba\(0(?:\.0)?,\s*0(?:\.0)?%,\s*0(?:\.0)?%,\s*0\.5\)$'
        }
    }

    Context 'CMYK Conversions' {
        It 'Converts RGB to CMYK' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'cmyk'
            $result | Should -Match '^cmyk\(0(?:\.0)?%,\s*100(?:\.0)?%,\s*100(?:\.0)?%,\s*0(?:\.0)?%\)$'
        }

        It 'Converts HEX to CMYK' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'cmyk'
            $result | Should -Match '^cmyk\(0(?:\.0)?%,\s*100(?:\.0)?%,\s*100(?:\.0)?%,\s*0(?:\.0)?%\)$'
        }

        It 'Converts white RGB to CMYK' {
            $result = Convert-Color -Color 'rgb(255, 255, 255)' -ToFormat 'cmyk'
            $result | Should -Match '^cmyk\(0(?:\.0)?%,\s*0(?:\.0)?%,\s*0(?:\.0)?%,\s*0(?:\.0)?%\)$'
        }

        It 'Converts black RGB to CMYK' {
            $result = Convert-Color -Color 'rgb(0, 0, 0)' -ToFormat 'cmyk'
            $result | Should -Match '^cmyk\(0(?:\.0)?%,\s*0(?:\.0)?%,\s*0(?:\.0)?%,\s*100(?:\.0)?%\)$'
        }
    }

    Context 'CMYKA Conversions' {
        It 'Converts RGBA to CMYKA' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'cmyka'
            $result | Should -Match 'cmyka\(0(?:\.0)?%,\s*100(?:\.0)?%,\s*100(?:\.0)?%,\s*0(?:\.0)?%,\s*0\.5\)$'
        }
    }

    Context 'NCOL Conversions' {
        It 'Converts RGB to NCOL' {
            $result = Convert-Color -Color 'rgb(255, 0, 0)' -ToFormat 'ncol'
            $result | Should -Match '^ncol\(R\d+(?:\.\d+)?,\s*\d+(?:\.\d+)?%,\s*\d+(?:\.\d+)?%\)$'
        }

        It 'Converts HEX to NCOL' {
            $result = Convert-Color -Color '#ff0000' -ToFormat 'ncol'
            $result | Should -Match '^ncol\(R\d+(?:\.\d+)?,\s*\d+(?:\.\d+)?%,\s*\d+(?:\.\d+)?%\)$'
        }
    }

    Context 'NCOLA Conversions' {
        It 'Converts RGBA to NCOLA' {
            $result = Convert-Color -Color 'rgba(255, 0, 0, 0.5)' -ToFormat 'ncola'
            $result | Should -Match 'ncola\(R\d+(?:\.\d+)?,\s*\d+(?:\.\d+)?%,\s*\d+(?:\.\d+)?%,\s*0\.5\)$'
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

