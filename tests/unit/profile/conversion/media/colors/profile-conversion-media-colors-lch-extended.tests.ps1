<#
tests/unit/profile-conversion-media-colors-lch-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/lch.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/lch.ps1 extended scenarios' {
    It 'Documents LCH/LCHa color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'LCH/LCHa Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsLch'
    }
    It 'Defines LAB to LCH polar conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-LabToLch'
        $c | Should -Match 'chroma'
        $c | Should -Match 'Normalize hue to 0-360'
    }
    It 'Defines RGB to LCH conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-RgbToLch'
        $c | Should -Match '_Convert-LchToRgb'
    }
}

