<#
tests/unit/profile-conversion-media-colors-hsl-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/hsl.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/hsl.ps1 extended scenarios' {
    It 'Documents HSL/HSLA color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HSL/HSLA Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsHsl'
    }
    It 'Defines HSL to RGB conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-HslToRgb'
        $c | Should -Match 'hueSector'
        $c | Should -Match 'chroma'
    }
    It 'Defines RGB to HSL conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-RgbToHsl'
        $c | Should -Match 'saturation'
        $c | Should -Match 'lightness'
    }
}

