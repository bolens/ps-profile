<#
tests/unit/profile-conversion-media-images-common-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/common.ps1'
}
Describe 'profile.d/conversion-modules/media/images/common.ps1 extended scenarios' {
    It 'Documents shared image conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Image media format conversion utilities - Common Helpers'
        $c | Should -Match 'Shared helper functions for all image format conversions'
    }
    It 'Defines _Ensure-ImageMagick with ImageMagick and GraphicsMagick detection' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Ensure-ImageMagick'
        $c | Should -Match 'Test-CachedCommand ''magick'''
        $c | Should -Match 'Get-ImageConversionToolMissingMessage'
    }
    It 'Provides _Convert-ImageFormat generic conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-ImageFormat'
        $c | Should -Match 'Initialize-FileConversion-MediaImagesCommon'
    }
}

