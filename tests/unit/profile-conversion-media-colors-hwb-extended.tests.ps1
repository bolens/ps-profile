<#
tests/unit/profile-conversion-media-colors-hwb-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/hwb.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/hwb.ps1 extended scenarios' {
    It 'Documents HWB/HWBA color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HWB/HWBA Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsHwb'
    }
    It 'Defines HWB to RGB conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-HwbToRgb'
        $c | Should -Match 'whitenessNormalized'
        $c | Should -Match 'blacknessNormalized'
    }
    It 'Defines RGB to HWB conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-RgbToHwb'
        $c | Should -Match 'hueNormalized'
        $c | Should -Match 'blackness'
    }
}

