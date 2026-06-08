<#
tests/unit/profile-clipboard-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/clipboard.ps1'
}
Describe 'profile.d/clipboard.ps1 extended scenarios' {
    It 'Declares essential tier for cross-platform clipboard helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Copy-ToClipboard and Get-FromClipboard with platform tools' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Copy-ToClipboard'
        $c | Should -Match 'Get-FromClipboard'
        $c | Should -Match 'Test-CachedCommand Set-Clipboard'
        $c | Should -Match 'wl-copy'
    }
    It 'Registers cb and pb clipboard aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'cb'"
        $c | Should -Match "Set-AgentModeAlias -Name 'pb'"
    }
}
