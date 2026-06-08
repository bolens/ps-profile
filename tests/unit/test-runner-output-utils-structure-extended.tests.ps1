<#
tests/unit/test-runner-output-utils-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/OutputSanitizer.psm1'
}
Describe 'scripts/utils/code-quality/modules/OutputSanitizer.psm1 structure extended scenarios' {
    It 'Documents output sanitization utilities for test runner' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'OutputSanitizer.psm1'
        $c | Should -Match 'sanitiz'
    }
    It 'Defines sanitization helpers using repo root pattern' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-RepoRootPattern'
        $c | Should -Match 'replacing repository roots'
    }
    It 'Exports output utility functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
    }
}
