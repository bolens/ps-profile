<#
tests/unit/test-runner-test-execution-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestRetry.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestRetry.psm1 structure extended scenarios' {
    It 'Documents test retry logic utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test retry logic utilities'
        $c | Should -Match 'TestRetry.psm1'
    }
    It 'Defines Invoke-TestWithRetry with MaxRetries support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-TestWithRetry'
        $c | Should -Match 'MaxRetries'
        $c | Should -Match 'ExponentialBackoff'
    }
    It 'Exports retry helpers for run-pester' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Invoke-TestWithRetry'
    }
}
