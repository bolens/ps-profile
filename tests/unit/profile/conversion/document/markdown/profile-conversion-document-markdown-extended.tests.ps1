<#
tests/unit/profile-conversion-document-markdown-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-markdown.ps1'
}
Describe 'profile.d/conversion-modules/document/document-markdown.ps1 extended scenarios' {
    It 'Documents Markdown document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Markdown document format conversion utilities'
        $c | Should -Match 'Markdown ↔ HTML, PDF, DOCX, LaTeX, RST'
    }
    It 'Defines Initialize-FileConversion-DocumentMarkdown with pandoc conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentMarkdown'
        $c | Should -Match '_ConvertTo-HtmlFromMarkdown'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Uses Ensure-DocumentLatexEngine for PDF-related conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-DocumentLatexEngine'
        $c | Should -Match 'Ensure-FileConversion-Documents'
    }
}
