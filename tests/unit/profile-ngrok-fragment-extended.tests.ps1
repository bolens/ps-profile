<#
tests/unit/profile-ngrok-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/ngrok.ps1'
}
Describe 'profile.d/ngrok.ps1 extended scenarios' {
    It 'Declares standard tier for web and development tunnel helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Defines Invoke-Ngrok guarded by Test-CachedCommand ngrok' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Ngrok'
        $c | Should -Match 'Test-CachedCommand ngrok'
    }
    It 'Registers ngrok and ngrok-http tunnel aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ngrok'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ngrok-http'"
    }
}
