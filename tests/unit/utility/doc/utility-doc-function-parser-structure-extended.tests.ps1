<#
tests/unit/utility-doc-function-parser-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocFunctionParser.psm1'
}
Describe 'scripts/utils/docs/modules/DocFunctionParser.psm1 structure extended scenarios' {
    It 'Documents function parsing utilities for docs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Function parsing utilities for documentation extraction'
        $c | Should -Match 'DocFunctionParser.psm1'
    }
    It 'Defines Parse-FunctionDocumentation from AST' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Parse-FunctionDocumentation'
        $c | Should -Match 'FunctionDefinitionAst'
        $c | Should -Match 'comment-based help'
    }
    It 'Imports DocParserRegex patterns' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DocParserRegex.psm1'
        $c | Should -Match 'DocHelpParser.psm1'
        $c | Should -Match 'Export-ModuleMember -Function Parse-FunctionDocumentation'
    }
}
