<#
tests/unit/utility-fragment-readme-parser-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/FragmentReadmeParser.psm1'
}
Describe 'scripts/utils/docs/modules/FragmentReadmeParser.psm1 structure extended scenarios' {
    It 'Documents fragment README parsing utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Fragment README parsing utilities'
        $c | Should -Match 'FragmentReadmeParser.psm1'
    }
    It 'Defines fragment metadata extraction helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-FragmentPurpose'
        $c | Should -Match 'Get-FragmentFunctions'
        $c | Should -Match 'Get-FragmentEnableHelpers'
    }
    It 'Imports FragmentReadmeRegex patterns' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FragmentReadmeRegex.psm1'
        $c | Should -Match 'Get-FunctionDescription'
        $c | Should -Match 'Export-ModuleMember'
    }
}
