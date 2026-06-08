<#
tests/unit/profile-dev-tools-diff-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/format/diff.ps1'
}
Describe 'profile.d/dev-tools-modules/format/diff.ps1 extended scenarios' {
    It 'Documents text comparison and diff utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Text comparison and diff utilities'
        $c | Should -Match 'Ensure-DevTools'
    }
    It 'Defines Compare-TextFiles with diff command fallback' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Compare-TextFiles'
        $c | Should -Match 'Initialize-DevTools-Diff'
        $c | Should -Match "Test-CachedCommand 'diff'"
    }
    It 'Registers diff-files and compare-files aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'diff-files'"
        $c | Should -Match "Set-AgentModeAlias -Name 'compare-files'"
    }
}
