<#
tests/unit/profile-open-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/open.ps1'
}
Describe 'profile.d/open.ps1 extended scenarios' {
    It 'Declares standard tier for cross-platform open helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Defines Open-Item with xdg-open and open fallbacks on non-Windows' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Open-Item'
        $c | Should -Match 'Test-CachedCommand xdg-open'
        $c | Should -Match 'Test-CachedCommand open'
    }
    It 'Registers open alias targeting Open-Item' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'open' -Target 'Open-Item'"
    }
}
