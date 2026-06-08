<#
tests/unit/profile-conversion-media-images-avif-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/avif.ps1'
}
Describe 'profile.d/conversion-modules/media/images/avif.ps1 extended scenarios' {
    It 'Documents AVIF image format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'AVIF Image Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaImagesAvif'
    }
    It 'Initializes AVIF conversions via common image helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaImagesCommon'
        $c | Should -Match '_ConvertFrom-AvifToPng'
        $c | Should -Match '_Convert-ImageFormat'
    }
    It 'Registers avif-to-png and png-to-avif entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'avif-to-png'
        $c | Should -Match 'ConvertTo-AvifFromPng'
        $c | Should -Match 'png-to-avif'
    }
}

