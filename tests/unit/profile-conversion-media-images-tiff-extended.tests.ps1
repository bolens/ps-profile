<#
tests/unit/profile-conversion-media-images-tiff-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/tiff.ps1'
}
Describe 'profile.d/conversion-modules/media/images/tiff.ps1 extended scenarios' {
    It 'Documents TIFF image format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TIFF Image Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaImagesTiff'
    }
    It 'Defines TIFF to PNG and PDF conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-TiffToPng'
        $c | Should -Match '_ConvertFrom-TiffToPdf'
        $c | Should -Match '_Convert-ImageFormat'
    }
    It 'Registers tiff-to-jpg and pdf-to-tiff aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'tiff-to-jpg'
        $c | Should -Match 'ConvertTo-TiffFromPdf'
        $c | Should -Match 'pdf-to-tiff'
    }
}

