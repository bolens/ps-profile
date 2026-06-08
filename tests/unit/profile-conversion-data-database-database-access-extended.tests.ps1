<#
tests/unit/profile-conversion-data-database-database-access-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/database/database-access.ps1'
}
Describe 'profile.d/conversion-modules/data/database/database-access.ps1 extended scenarios' {
    It 'Documents Microsoft Access database format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Microsoft Access database format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-DatabaseAccess with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DatabaseAccess'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers access-to-json and mdb-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'access-to-json'
        $c | Should -Match 'mdb-to-json'
    }
}
