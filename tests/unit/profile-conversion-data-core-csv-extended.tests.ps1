<#
tests/unit/profile-conversion-data-core-csv-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/core/csv.ps1'
}
Describe 'profile.d/conversion-modules/data/core/csv.ps1 extended scenarios' {
    It 'Documents CSV format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'CSV format conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreBasic'
    }
    It 'Defines Initialize-FileConversion-CoreBasicCsv with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreBasicCsv'
        $c | Should -Match '_ConvertFrom-CsvToJson'
    }
    It 'Registers csv-to-json and json-to-csv entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'csv-to-json'
        $c | Should -Match 'json-to-csv'
    }
}
