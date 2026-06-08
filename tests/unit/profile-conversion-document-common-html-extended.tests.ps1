<#
tests/unit/profile-conversion-document-common-html-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-common-html.ps1'
}
Describe 'profile.d/conversion-modules/document/document-common-html.ps1 extended scenarios' {
    It 'Documents HTML document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HTML document format conversion utilities'
        $c | Should -Match 'HTML to Markdown, PDF, and LaTeX'
    }
    It 'Defines Initialize-FileConversion-DocumentCommonHtml with pandoc' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentCommonHtml'
        $c | Should -Match '_ConvertFrom-HtmlToMarkdown'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Uses Ensure-DocumentLatexEngine before pandoc execution' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-DocumentLatexEngine'
        $c | Should -Match 'Initialize-FileConversion-DocumentCommon'
    }
}
