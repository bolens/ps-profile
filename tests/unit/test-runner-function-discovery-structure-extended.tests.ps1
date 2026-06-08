<#
tests/unit/test-runner-function-discovery-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/FunctionDiscovery.psm1'
}
Describe 'scripts/utils/code-quality/modules/FunctionDiscovery.psm1 structure extended scenarios' {
    It 'Documents function discovery utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Function discovery utilities'
        $c | Should -Match 'FunctionDiscovery.psm1'
    }
    It 'Defines Get-FunctionsFromPath scanner' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-FunctionsFromPath'
        $c | Should -Match 'Set-AgentModeFunction'
        $c | Should -Match 'RepoRoot'
    }
    It 'Imports FunctionNamingValidator and FileContent' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FunctionNamingValidator.psm1'
        $c | Should -Match 'FileContent.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
