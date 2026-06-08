<#
tests/unit/profile-conversion-document-markdown-dialects-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-markdown-dialects.ps1'
}
Describe 'profile.d/conversion-modules/document/document-markdown-dialects.ps1 extended scenarios' {
    It 'Documents markdown dialect conversion via pandoc format mapping' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'markdown dialect alias'
        $c | Should -Match '\(gfm, obsidian, multimarkdown, etc.\)'
    }
    It 'Defines Initialize-FileConversion-DocumentMarkdownDialects with pandoc' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentMarkdownDialects'
        $c | Should -Match 'Invoke-MarkdownDialectConversion'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers gfm-to-obsidian and obsidian-to-gfm aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'gfm-to-obsidian'"
        $c | Should -Match "Set-AgentModeAlias -Name 'obsidian-to-gfm'"
    }
}
