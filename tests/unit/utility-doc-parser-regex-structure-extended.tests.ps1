<#
tests/unit/utility-doc-parser-regex-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocParserRegex.psm1'
}
Describe 'scripts/utils/docs/modules/DocParserRegex.psm1 structure extended scenarios' {
    It 'Documents documentation parser regex pattern definitions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Documentation parser regex pattern definitions'
        $c | Should -Match 'DocParserRegex.psm1'
    }
    It 'Defines compiled comment-based help regex patterns' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'regexCommentBlock'
        $c | Should -Match 'regexParameter'
        $c | Should -Match 'regexExample'
        $c | Should -Match 'RegexOptions]::Compiled'
    }
    It 'Exports regex patterns as module variables' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Variable'
        $c | Should -Match 'regexLink'
        $c | Should -Match 'regexCodeLine'
    }
}
