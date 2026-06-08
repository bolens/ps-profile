<#
tests/unit/profile-conversion-media-images-webp-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/webp.ps1'
}
Describe 'profile.d/conversion-modules/media/images/webp.ps1 extended scenarios' {
    It 'Documents WebP image format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'WebP Image Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaImagesWebp'
    }
    It 'Defines WebP to PNG and GIF conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-WebpToPng'
        $c | Should -Match '_ConvertFrom-WebpToGif'
        $c | Should -Match '_Convert-ImageFormat'
    }
    It 'Registers webp-to-jpeg and gif-to-webp entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'webp-to-jpeg'
        $c | Should -Match 'ConvertTo-WebpFromGif'
        $c | Should -Match 'gif-to-webp'
    }
}

