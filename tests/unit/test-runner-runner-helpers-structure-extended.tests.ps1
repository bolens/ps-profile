<#
tests/unit/test-runner-runner-helpers-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestRunnerHelpers.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestRunnerHelpers.psm1 structure extended scenarios' {
    It 'Documents test runner helper utilities module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestRunnerHelpers.psm1'
        $c | Should -Match 'test runner'
    }
    It 'Defines Invoke-TestDryRun helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-TestDryRun'
        $c | Should -Match 'DryRun'
    }
    It 'Exports Invoke-TestDryRun' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Invoke-TestDryRun'
    }
}

