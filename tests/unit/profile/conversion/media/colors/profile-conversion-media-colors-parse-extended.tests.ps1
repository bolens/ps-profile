<#
tests/unit/profile-conversion-media-colors-parse-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/parse.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/parse.ps1 extended scenarios' {
    It 'Documents color parsing utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Color Parsing Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsParse'
    }
    It 'Defines _Parse-Color with HEX and named color support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Parse-Color'
        $c | Should -Match 'CssNamedColors'
        $c | Should -Match '#rrggbb'
    }
    It 'Routes HSL HWB CMYK and LAB color string formats' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '# Parse HSL'
        $c | Should -Match '# Parse HWB'
        $c | Should -Match '_Convert-CmykToRgb'
        $c | Should -Match '_Convert-LabToRgb'
    }
}

