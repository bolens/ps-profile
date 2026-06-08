<#
tests/unit/profile-conversion-document-office-excel-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-office-excel.ps1'
}
Describe 'profile.d/conversion-modules/document/document-office-excel.ps1 extended scenarios' {
    It 'Documents Excel XLSX/XLS spreadsheet conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Excel format conversion utilities'
        $c | Should -Match 'ImportExcel PowerShell module'
    }
    It 'Defines Initialize-FileConversion-DocumentOfficeExcel with pandoc xlsx fallback' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficeExcel'
        $c | Should -Match '_ConvertFrom-ExcelToCsv'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers excel-to-csv and xlsx-to-csv aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'excel-to-csv'"
        $c | Should -Match "Set-AgentModeAlias -Name 'xlsx-to-csv'"
    }
}
