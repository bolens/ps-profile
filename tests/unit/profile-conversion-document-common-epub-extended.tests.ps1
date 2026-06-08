<#
tests/unit/profile-conversion-document-common-epub-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-common-epub.ps1'
}
Describe 'profile.d/conversion-modules/document/document-common-epub.ps1 extended scenarios' {
    It 'Documents EPUB document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'EPUB document format conversion utilities'
        $c | Should -Match 'pandoc as the underlying tool'
    }
    It 'Defines Initialize-FileConversion-DocumentCommonEpub with epub conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentCommonEpub'
        $c | Should -Match '_ConvertFrom-EpubToMarkdown'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers epub-to-markdown and markdown-to-epub aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'epub-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'markdown-to-epub'"
    }
}
