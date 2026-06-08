<#
tests/unit/profile-conversion-media-images-bmp-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/bmp.ps1'
}
Describe 'profile.d/conversion-modules/media/images/bmp.ps1 extended scenarios' {
    It 'Documents BMP image format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'BMP Image Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaImagesBmp'
    }
    It 'Defines BMP to PNG and JPEG conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-BmpToPng'
        $c | Should -Match '_ConvertFrom-BmpToJpeg'
        $c | Should -Match '_Convert-ImageFormat'
    }
    It 'Registers bmp-to-png and jpeg-to-bmp aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'bmp-to-png'
        $c | Should -Match 'ConvertTo-BmpFromJpeg'
        $c | Should -Match 'jpeg-to-bmp'
    }
}

