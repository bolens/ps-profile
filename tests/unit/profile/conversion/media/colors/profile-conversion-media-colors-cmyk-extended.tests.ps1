<#
tests/unit/profile-conversion-media-colors-cmyk-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/cmyk.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/cmyk.ps1 extended scenarios' {
    It 'Documents CMYK/CMYKA color conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'CMYK/CMYKA Color Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsCmyk'
    }
    It 'Defines CMYK to RGB conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-CmykToRgb'
        $c | Should -Match 'cyanNormalized'
        $c | Should -Match 'keyNormalized'
    }
    It 'Defines RGB to CMYK conversion helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-RgbToCmyk'
        $c | Should -Match 'redNormalized'
        $c | Should -Match 'magenta'
    }
}

