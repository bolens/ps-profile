<#
tests/unit/test-runner-test-result-validation-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestResultValidation.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestResultValidation.psm1 structure extended scenarios' {
    It 'Documents test result validation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test result validation utilities'
        $c | Should -Match 'TestResultValidation.psm1'
    }
    It 'Defines Test-TestResultIntegrity validation helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-TestResultIntegrity'
        $c | Should -Match 'ValidationRules'
        $c | Should -Match 'ExpectedTests'
    }
    It 'Imports CommonEnums for severity handling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'CommonEnums.psm1'
        $c | Should -Match 'SeverityLevel'
        $c | Should -Match 'Export-ModuleMember'
    }
}
