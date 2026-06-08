<#
tests/unit/test-runner-link-guide-drift-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/link-guide-drift.ps1'
}
Describe 'scripts/utils/code-quality/link-guide-drift.ps1 extended scenarios' {
    It 'Documents drift linking for developer guides' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Links developer guides in docs/guides'
        $c | Should -Match 'drift link'
    }
    It 'Supports DryRun Refresh and GuidePath parameters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DryRun'
        $c | Should -Match 'Refresh'
        $c | Should -Match 'GuidePath'
    }
    It 'Defines explicit anchor maps for core guides' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'GuideAnchorMap'
        $c | Should -Match 'MODULE_LOADING_STANDARD\.md'
        $c | Should -Match 'FRAGMENT_COMMAND_ACCESS\.md'
        $c | Should -Match 'TYPE_SAFETY\.md'
    }
}
