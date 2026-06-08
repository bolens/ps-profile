<#
tests/unit/profile-conversion-media-images-ico-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/ico.ps1'
}
Describe 'profile.d/conversion-modules/media/images/ico.ps1 extended scenarios' {
    It 'Documents ICO image format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ICO Image Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaImagesIco'
    }
    It 'Defines ICO to PNG and JPEG conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-IcoToPng'
        $c | Should -Match '_ConvertFrom-IcoToJpeg'
        $c | Should -Match '_Convert-ImageFormat'
    }
    It 'Registers ico-to-png and png-to-ico aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ico-to-png'
        $c | Should -Match 'ConvertTo-IcoFromPng'
        $c | Should -Match 'png-to-ico'
    }
}

