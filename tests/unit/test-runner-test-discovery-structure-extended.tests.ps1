<#
tests/unit/test-runner-test-discovery-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestLister.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestLister.psm1 structure extended scenarios' {
    It 'Documents test listing utilities for discovery' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test listing utilities'
        $c | Should -Match 'TestLister.psm1'
    }
    It 'Defines Get-TestList for scanning test file paths' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestList'
        $c | Should -Match 'TestPaths'
        $c | Should -Match 'RepoRoot'
    }
    It 'Exports listing helpers for run-pester' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Get-TestList'
    }
}
