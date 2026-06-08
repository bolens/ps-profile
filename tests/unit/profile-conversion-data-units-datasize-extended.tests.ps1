<#
tests/unit/profile-conversion-data-units-datasize-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/datasize.ps1'
}
Describe 'profile.d/conversion-modules/data/units/datasize.ps1 extended scenarios' {
    It 'Documents Data Size unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Data Size unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsDataSize with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsDataSize'
        $c | Should -Match '_Convert-DataSize'
    }
    It 'Registers datasize and bytes-to-datasize entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'datasize'
        $c | Should -Match 'bytes-to-datasize'
    }
}
