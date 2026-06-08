<#
tests/unit/profile-conversion-media-colors-oklch-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/oklch.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/oklch.ps1 extended scenarios' {
    It 'Documents OKLCH/OKLCHa color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'OKLCH/OKLCHa Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsOklch'
    }
    It 'Defines OKLAB to OKLCH polar conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-OklabToOklch'
        $c | Should -Match '_Convert-OklchToOklab'
    }
    It 'Defines RGB to OKLCH round-trip conversion chain' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-RgbToOklch'
        $c | Should -Match '_Convert-OklchToRgb'
        $c | Should -Match '_Convert-RgbToOklab'
    }
}
