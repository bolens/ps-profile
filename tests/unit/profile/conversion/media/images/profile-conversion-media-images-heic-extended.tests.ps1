<#
tests/unit/profile-conversion-media-images-heic-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/heic.ps1'
}
Describe 'profile.d/conversion-modules/media/images/heic.ps1 extended scenarios' {
    It 'Documents HEIC/HEIF image format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HEIC/HEIF Image Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaImagesHeic'
    }
    It 'Defines HEIC to JPEG and PNG conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-HeicToJpeg'
        $c | Should -Match '_ConvertFrom-HeicToPng'
        $c | Should -Match '_Convert-ImageFormat'
    }
    It 'Registers heic-to-jpg and png-to-heif entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'heic-to-jpg'
        $c | Should -Match 'ConvertTo-HeicFromPng'
        $c | Should -Match 'png-to-heif'
    }
}

