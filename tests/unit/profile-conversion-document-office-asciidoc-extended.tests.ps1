<#
tests/unit/profile-conversion-document-office-asciidoc-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-office-asciidoc.ps1'
}
Describe 'profile.d/conversion-modules/document/document-office-asciidoc.ps1 extended scenarios' {
    It 'Documents AsciiDoc document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'AsciiDoc format conversion utilities'
        $c | Should -Match 'pandoc or asciidoc tools'
    }
    It 'Defines Initialize-FileConversion-DocumentOfficeAsciidoc with pandoc asciidoc conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficeAsciidoc'
        $c | Should -Match '_ConvertFrom-AsciidocToMarkdown'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers asciidoc-to-markdown and adoc-to-markdown aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'asciidoc-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'adoc-to-markdown'"
    }
}
