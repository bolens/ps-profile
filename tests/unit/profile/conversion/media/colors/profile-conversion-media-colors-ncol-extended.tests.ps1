<#
tests/unit/profile-conversion-media-colors-ncol-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/ncol.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/ncol.ps1 extended scenarios' {
    It 'Documents NCOL/NCOLA color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'NCOL/NCOLA Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsNcol'
    }
    It 'Defines _Convert-NcolToRgb with Natural Color System hue codes' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-NcolToRgb'
        $c | Should -Match 'Natural Color System'
    }
    It 'Routes NCOL conversion through HWB helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-HwbToRgb'
        $c | Should -Match 'Whiteness'
        $c | Should -Match 'Blackness'
    }
}
