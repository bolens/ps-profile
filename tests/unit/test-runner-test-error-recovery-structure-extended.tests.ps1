<#
tests/unit/test-runner-test-error-recovery-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestErrorRecovery.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestErrorRecovery.psm1 structure extended scenarios' {
    It 'Documents enhanced error recovery utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Enhanced error recovery utilities'
        $c | Should -Match 'TestErrorRecovery.psm1'
    }
    It 'Defines Invoke-WithErrorRecovery wrapper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-WithErrorRecovery'
        $c | Should -Match 'MaxRecoveryAttempts'
        $c | Should -Match 'RecoveryActions'
    }
    It 'Imports Logging module for recovery messages' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Logging.psm1'
        $c | Should -Match 'Export-ModuleMember -Function Invoke-WithErrorRecovery'
    }
}
