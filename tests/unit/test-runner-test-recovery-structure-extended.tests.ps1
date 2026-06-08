<#
tests/unit/test-runner-test-recovery-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestRecovery.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestRecovery.psm1 structure extended scenarios' {
    It 'Documents test execution recovery utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test execution recovery utilities'
        $c | Should -Match 'TestRecovery.psm1'
    }
    It 'Defines Invoke-TestExecutionRecovery helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-TestExecutionRecovery'
        $c | Should -Match 'transient issues'
    }
    It 'Imports Logging and exports recovery helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Logging.psm1'
        $c | Should -Match 'Export-ModuleMember -Function Invoke-TestExecutionRecovery'
    }
}
