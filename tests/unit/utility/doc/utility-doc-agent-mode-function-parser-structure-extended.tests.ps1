<#
tests/unit/utility-doc-agent-mode-function-parser-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocAgentModeFunctionParser.psm1'
}
Describe 'scripts/utils/docs/modules/DocAgentModeFunctionParser.psm1 structure extended scenarios' {
    It 'Documents Set-AgentModeFunction parsing utilities for docs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Dynamic function registration parsing utilities for documentation extraction'
        $c | Should -Match 'DocAgentModeFunctionParser.psm1'
    }
    It 'Defines Parse-AgentModeFunctionsFromFile' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Parse-DynamicFunctionsFromFile'
        $c | Should -Match 'Parse-AgentModeFunctionsFromFile'
        $c | Should -Match 'Set-AgentModeFunction'
        $c | Should -Match 'Register-LazyFunction'
        $c | Should -Match 'Set-Item'
        $c | Should -Match 'ExistingFunctionNames'
    }
    It 'Imports shared help and alias parser modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DocHelpParser.psm1'
        $c | Should -Match 'DocAliasParser.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
