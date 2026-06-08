<#
tests/unit/test-runner-test-comprehensive-reporting-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestComprehensiveReporting.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestComprehensiveReporting.psm1 structure extended scenarios' {
    It 'Documents comprehensive test reporting module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestComprehensiveReporting.psm1'
        $c | Should -Match 'comprehensive'
    }
    It 'Defines report generation entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-ComprehensiveTestReport'
        $c | Should -Match 'comprehensive'
    }
    It 'Exports comprehensive reporting helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
    }
}

