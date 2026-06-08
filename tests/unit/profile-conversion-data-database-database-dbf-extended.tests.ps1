<#
tests/unit/profile-conversion-data-database-database-dbf-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/database/database-dbf.ps1'
}
Describe 'profile.d/conversion-modules/data/database/database-dbf.ps1 extended scenarios' {
    It 'Documents DBF \(dBase\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DBF \(dBase\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-DatabaseDbf with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DatabaseDbf'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers dbf-to-json and dbf-to-csv entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'dbf-to-json'
        $c | Should -Match 'dbf-to-csv'
    }
}
