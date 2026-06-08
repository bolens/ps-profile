<#
tests/unit/test-runner-test-categorization-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestCategorization.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestCategorization.psm1 structure extended scenarios' {
    It 'Documents test categorization module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestCategorization.psm1'
        $c | Should -Match 'categorization'
    }
    It 'Defines Get-TestCategory helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestCategory'
    }
    It 'Exports categorization function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Get-TestCategory'
    }
}

