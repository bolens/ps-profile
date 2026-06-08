<#
tests/unit/profile-tailscale-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/tailscale.ps1'
}
Describe 'profile.d/tailscale.ps1 extended scenarios' {
    It 'Declares standard tier for Tailscale VPN helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'PowerShell.Profile.Tailscale'
    }
    It 'Defines Invoke-Tailscale guarded by command availability checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Tailscale'
        $c | Should -Match 'Test-CachedCommand'
    }
    It 'Registers tailscale and ts-status shorthand aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'tailscale'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ts-status'"
    }
}
