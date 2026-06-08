<#
tests/unit/profile-conversion-media-colors-oklab-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/oklab.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/oklab.ps1 extended scenarios' {
    It 'Documents OKLAB/OKLABa color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'OKLAB/OKLABa Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsOklab'
    }
    It 'Defines RGB to OKLAB conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-RgbToOklab'
        $c | Should -Match '_Convert-RgbToLinearRgb'
        $c | Should -Match 'LMS cone response'
    }
    It 'Defines OKLAB to RGB conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-OklabToRgb'
        $c | Should -Match '_Convert-LinearRgbToRgb'
        $c | Should -Match 'LMS to linear RGB'
    }
}

