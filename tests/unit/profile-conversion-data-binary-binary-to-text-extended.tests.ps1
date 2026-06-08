<#
tests/unit/profile-conversion-data-binary-binary-to-text-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-to-text.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-to-text.ps1 extended scenarios' {
    It 'Documents Binary-to-text conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Binary-to-text conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinaryToText with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinaryToText'
        $c | Should -Match '_ConvertFrom-BsonToCsv'
    }
    It 'Registers bson-to-csv and bson-to-yaml entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'bson-to-csv'
        $c | Should -Match 'bson-to-yaml'
    }
}
