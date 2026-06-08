<#
tests/unit/test-runner-test-config-file-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestConfigFile.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestConfigFile.psm1 structure extended scenarios' {
    It 'Documents configuration file utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Configuration file utilities'
        $c | Should -Match 'TestConfigFile.psm1'
    }
    It 'Defines save and load configuration helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Save-TestConfig'
        $c | Should -Match 'Load-TestConfig'
        $c | Should -Match 'ConvertTo-Hashtable'
    }
    It 'Imports JsonUtilities for config serialization' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'JsonUtilities.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
