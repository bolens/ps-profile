<#
tests/unit/profile-vite-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/vite.ps1'
}
Describe 'profile.d/vite.ps1 extended scenarios' {
    It 'Declares standard tier for web and development Vite helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Defines Invoke-Vite and Start-ViteDev wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Vite'
        $c | Should -Match 'Start-ViteDev'
    }
    It 'Registers vite vite-dev and create-vite aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'vite'"
        $c | Should -Match "Set-AgentModeAlias -Name 'vite-dev'"
    }
}
