<#
tests/unit/profile-conversion-document-markdown-notes-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-markdown-notes.ps1'
}
Describe 'profile.d/conversion-modules/document/document-markdown-notes.ps1 extended scenarios' {
    It 'Documents note-app markdown migration tools' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Note-app markdown migration tools'
        $c | Should -Match 'Joplin, Obsidian, Notion, Logseq'
    }
    It 'Defines wikilink and Notion export conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentMarkdownNotes'
        $c | Should -Match 'ConvertTo-WikilinksFromMarkdownLinks'
        $c | Should -Match 'Export-NotionPageToMarkdown'
    }
    It 'Registers md-links-to-wikilinks and notion-to-markdown aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'md-links-to-wikilinks'"
        $c | Should -Match "Set-AgentModeAlias -Name 'notion-to-markdown'"
    }
}
