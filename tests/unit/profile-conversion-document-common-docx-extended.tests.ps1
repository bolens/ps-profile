<#
tests/unit/profile-conversion-document-common-docx-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-common-docx.ps1'
}
Describe 'profile.d/conversion-modules/document/document-common-docx.ps1 extended scenarios' {
    It 'Documents DOCX document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DOCX document format conversion utilities'
        $c | Should -Match 'pandoc as the underlying tool'
    }
    It 'Defines Initialize-FileConversion-DocumentCommonDocx with docx conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentCommonDocx'
        $c | Should -Match '_ConvertFrom-DocxToMarkdown'
        $c | Should -Match '_ConvertTo-HtmlFromDocx'
    }
    It 'Registers docx-to-markdown and docx-to-pdf public aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-CachedCommand 'pandoc'"
        $c | Should -Match "Set-AgentModeAlias -Name 'docx-to-markdown'"
        $c | Should -Match 'Ensure-FileConversion-Documents'
    }
}
