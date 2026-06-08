<#
tests/unit/profile-conversion-data-structured-edn-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/edn.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/edn.ps1 extended scenarios' {
    It 'Documents EDN \(Extensible Data Notation\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'EDN \(Extensible Data Notation\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Edn with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Edn'
        $c | Should -Match '_ConvertFrom-EdnToJson'
    }
    It 'Registers edn-to-json and json-to-edn entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'edn-to-json'
        $c | Should -Match 'json-to-edn'
    }
}
