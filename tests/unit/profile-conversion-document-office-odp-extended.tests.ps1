<#
tests/unit/profile-conversion-document-office-odp-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-office-odp.ps1'
}
Describe 'profile.d/conversion-modules/document/document-office-odp.ps1 extended scenarios' {
    It 'Documents ODP OpenDocument presentation conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ODP \(OpenDocument Presentation\) format conversion utilities'
        $c | Should -Match 'pandoc or LibreOffice'
    }
    It 'Defines Initialize-FileConversion-DocumentOfficeOdp with presentation conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficeOdp'
        $c | Should -Match '_ConvertFrom-OdpToPdf'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers odp-to-pdf and odp-to-pptx aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'odp-to-pdf'"
        $c | Should -Match "Set-AgentModeAlias -Name 'odp-to-pptx'"
    }
}
