<#
tests/unit/profile-conversion-media-colors-hex-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/hex.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/hex.ps1 extended scenarios' {
    It 'Documents HEX color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HEX Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsHex'
    }
    It 'Defines _Convert-RgbToHex with alpha channel support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-RgbToHex'
        $c | Should -Match 'IncludeAlpha'
        $c | Should -Match '#rrggbb'
    }
    It 'Clamps RGB components to valid byte range' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'redClamped'
        $c | Should -Match 'greenClamped'
        $c | Should -Match 'blueClamped'
    }
}

