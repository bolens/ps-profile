<#
tests/unit/utility-fragment-readme-regex-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/FragmentReadmeRegex.psm1'
}
Describe 'scripts/utils/docs/modules/FragmentReadmeRegex.psm1 structure extended scenarios' {
    It 'Documents fragment README regex pattern definitions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Fragment README regex pattern definitions'
        $c | Should -Match 'FragmentReadmeRegex.psm1'
    }
    It 'Defines compiled fragment parsing regex patterns' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'regexFunction'
        $c | Should -Match 'regexMultilineCommentStart'
        $c | Should -Match 'regexDecorativeEquals'
    }
    It 'Exports fragment regex variables' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Variable'
        $c | Should -Match 'regexCommentLine'
        $c | Should -Match 'regexInlineComment'
    }
}
