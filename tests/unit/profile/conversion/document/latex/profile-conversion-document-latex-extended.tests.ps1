<#
tests/unit/profile-conversion-document-latex-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-latex.ps1'
}
Describe 'profile.d/conversion-modules/document/document-latex.ps1 extended scenarios' {
    It 'Documents LaTeX document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'LaTeX document format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Documents'
    }
    It 'Defines Initialize-FileConversion-DocumentLaTeX with pandoc latex conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentLaTeX'
        $c | Should -Match '_ConvertFrom-LaTeXToMarkdown'
        $c | Should -Match '_ConvertTo-HtmlFromLaTeX'
    }
    It 'Guards conversions with Test-CachedCommand pandoc' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-CachedCommand 'pandoc'"
        $c | Should -Match 'Ensure-DocumentLatexEngine'
    }
}
