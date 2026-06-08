<#
tests/unit/profile-conversion-data-scientific-scientific-matlab-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-matlab.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-matlab.ps1 extended scenarios' {
    It 'Documents MATLAB \.mat format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'MATLAB \.mat format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificMatlab with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificMatlab'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers matlab-to-json and mat-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'matlab-to-json'
        $c | Should -Match 'mat-to-json'
    }
}
