<#
tests/unit/profile-conversion-data-scientific-scientific-fits-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-fits.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-fits.ps1 extended scenarios' {
    It 'Documents FITS format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FITS format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificFits with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificFits'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers fits-to-json and fits-to-csv entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'fits-to-json'
        $c | Should -Match 'fits-to-csv'
    }
}
