<#
tests/unit/utility-doc-parser-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocParser.psm1'
}
Describe 'scripts/utils/docs/modules/DocParser.psm1 structure extended scenarios' {
    It 'Documents documentation parser utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Documentation parser utilities'
        $c | Should -Match 'DocParser.psm1'
    }
    It 'Imports specialized parser submodules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DocParserRegex.psm1'
        $c | Should -Match 'DocFunctionParser.psm1'
        $c | Should -Match 'DocAgentModeFunctionParser.psm1'
        $c | Should -Match 'DocAliasParser.psm1'
    }
    It 'Defines Get-DocumentedCommands aggregator' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-DocumentedCommands'
        $c | Should -Match 'Parse-DynamicFunctionsFromFile'
        $c | Should -Match 'ProfilePath'
        $c | Should -Match 'Export-ModuleMember'
    }
}
