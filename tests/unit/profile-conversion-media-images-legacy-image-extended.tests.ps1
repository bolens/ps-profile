<#
tests/unit/profile-conversion-media-images-legacy-image-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/legacy-image.ps1'
}
Describe 'profile.d/conversion-modules/media/images/legacy-image.ps1 extended scenarios' {
    It 'Documents legacy image conversion and resizing utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Image media format conversion utilities'
        $c | Should -Match 'Image conversion and resizing'
    }
    It 'Defines Initialize-FileConversion-MediaImages with magick helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaImages'
        $c | Should -Match '_Convert-Image'
        $c | Should -Match '_Resize-Image'
    }
    It 'Registers image-convert and image-resize aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-Image'
        $c | Should -Match 'image-convert'
        $c | Should -Match 'image-resize'
    }
}

