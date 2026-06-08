<#
tests/unit/profile-conversion-media-colors-convert-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/convert.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/convert.ps1 extended scenarios' {
    It 'Documents color conversion routing and public functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Color Conversion Routing and Public Functions'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsConvert'
    }
    It 'Defines _Convert-ColorFormat with multi-format ValidateSet' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-ColorFormat'
        $c | Should -Match '_Parse-Color'
        $c | Should -Match 'oklch'
    }
    It 'Registers Convert-Color and Parse-Color with aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-Color'
        $c | Should -Match 'color-convert'
        $c | Should -Match 'color-parse'
    }
}

