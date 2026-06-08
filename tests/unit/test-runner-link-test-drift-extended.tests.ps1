<#
tests/unit/test-runner-link-test-drift-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/link-test-drift.ps1'
}
Describe 'scripts/utils/code-quality/link-test-drift.ps1 extended scenarios' {
    It 'Documents drift linking for Pester test files' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Links Pester test files to their source targets'
        $c | Should -Match 'drift link'
    }
    It 'Supports DryRun Refresh and TestPath parameters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DryRun'
        $c | Should -Match 'Refresh'
        $c | Should -Match 'TestPath'
    }
    It 'Resolves sources from tests profile and scripts lib roots' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'testsRoot'
        $c | Should -Match 'profileRoot'
        $c | Should -Match 'scriptsLibRoot'
    }
}

