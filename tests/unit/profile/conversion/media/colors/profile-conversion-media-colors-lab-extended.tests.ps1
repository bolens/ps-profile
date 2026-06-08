<#
tests/unit/profile-conversion-media-colors-lab-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/lab.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/lab.ps1 extended scenarios' {
    It 'Documents LAB/LABa color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'LAB/LABa Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsLab'
    }
    It 'Defines RGB to XYZ and XYZ to LAB conversion chain' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-RgbToXyz'
        $c | Should -Match '_Convert-XyzToLab'
        $c | Should -Match 'D65'
    }
    It 'Defines LAB to RGB round-trip helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-LabToRgb'
        $c | Should -Match '_Convert-RgbToLab'
        $c | Should -Match '_Convert-LabToXyz'
    }
}

