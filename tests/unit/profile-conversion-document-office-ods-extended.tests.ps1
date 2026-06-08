<#
tests/unit/profile-conversion-document-office-ods-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-office-ods.ps1'
}
Describe 'profile.d/conversion-modules/document/document-office-ods.ps1 extended scenarios' {
    It 'Documents ODS OpenDocument spreadsheet conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ODS \(OpenDocument Spreadsheet\) format conversion utilities'
        $c | Should -Match 'pandoc or LibreOffice'
    }
    It 'Defines Initialize-FileConversion-DocumentOfficeOds with pandoc and libreoffice fallbacks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficeOds'
        $c | Should -Match '_ConvertFrom-OdsToCsv'
        $c | Should -Match "Test-CachedCommand 'libreoffice'"
    }
    It 'Registers ods-to-csv and csv-to-ods aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ods-to-csv'"
        $c | Should -Match "Set-AgentModeAlias -Name 'csv-to-ods'"
    }
}
