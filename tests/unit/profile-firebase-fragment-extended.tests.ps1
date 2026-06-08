<#
tests/unit/profile-firebase-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/firebase.ps1'
}
Describe 'profile.d/firebase.ps1 extended scenarios' {
    It 'Declares standard tier for web and development Firebase helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Defines Invoke-Firebase guarded by Test-CachedCommand firebase' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Firebase'
        $c | Should -Match 'Test-CachedCommand firebase'
    }
    It 'Registers fb shorthand alias for Invoke-Firebase' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'fb'"
        $c | Should -Match 'PowerShell.Profile.Firebase'
    }
}
