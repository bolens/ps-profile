<#
tests/unit/utility-doc-alias-parser-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocAliasParser.psm1'
}
Describe 'scripts/utils/docs/modules/DocAliasParser.psm1 structure extended scenarios' {
    It 'Documents alias parsing utilities for docs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Alias parsing utilities for documentation extraction'
        $c | Should -Match 'DocAliasParser.psm1'
    }
    It 'Defines Parse-AliasesFromFile with Set-AgentModeAlias support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Parse-AliasesFromFile'
        $c | Should -Match 'Set-AgentModeAlias'
        $c | Should -Match 'Set-Alias'
    }
    It 'Imports DocParserRegex and optional lib modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DocParserRegex.psm1'
        $c | Should -Match 'FileContent.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
