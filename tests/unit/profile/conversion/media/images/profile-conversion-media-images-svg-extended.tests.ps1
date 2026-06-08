<#
tests/unit/profile-conversion-media-images-svg-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/images/svg.ps1'
}
Describe 'profile.d/conversion-modules/media/images/svg.ps1 extended scenarios' {
    It 'Documents SVG image format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'SVG Image Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaImagesSvg'
    }
    It 'Defines SVG to PNG and PDF conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-SvgToPng'
        $c | Should -Match '_ConvertFrom-SvgToPdf'
        $c | Should -Match '_Convert-ImageFormat'
    }
    It 'Registers svg-to-jpeg and png-to-svg entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'svg-to-jpeg'
        $c | Should -Match 'ConvertTo-SvgFromPng'
        $c | Should -Match 'png-to-svg'
    }
}

