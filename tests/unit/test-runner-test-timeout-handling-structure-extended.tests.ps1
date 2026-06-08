<#
tests/unit/test-runner-test-timeout-handling-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestTimeoutHandling.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestTimeoutHandling.psm1 structure extended scenarios' {
    It 'Documents test timeout handling utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test timeout handling utilities'
        $c | Should -Match 'TestTimeoutHandling.psm1'
    }
    It 'Defines Invoke-PesterWithTimeout execution helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-PesterWithTimeout'
        $c | Should -Match 'Timeout'
        $c | Should -Match 'RunNumber'
    }
    It 'Imports Logging and JsonUtilities modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Logging.psm1'
        $c | Should -Match 'JsonUtilities.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
