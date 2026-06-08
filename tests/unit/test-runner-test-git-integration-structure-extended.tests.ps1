<#
tests/unit/test-runner-test-git-integration-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestGitIntegration.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestGitIntegration.psm1 structure extended scenarios' {
    It 'Documents git integration helpers for test runner' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestGitIntegration.psm1'
        $c | Should -Match 'git'
    }
    It 'Detects changed files or test scope from git' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'git'
        $c | Should -Match 'Changed'
        $c | Should -Match 'Diff'
    }
    It 'Exports git integration functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
    }
}

