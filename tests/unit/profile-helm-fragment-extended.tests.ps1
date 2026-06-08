<#
tests/unit/profile-helm-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/helm.ps1'
}
Describe 'profile.d/helm.ps1 extended scenarios' {
    It 'Declares standard tier for Kubernetes package management helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: cloud, containers, development'
    }
    It 'Defines Invoke-Helm guarded by Test-CachedCommand helm' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Helm'
        $c | Should -Match 'Test-CachedCommand helm'
    }
    It 'Registers helm alias and documents PowerShell.Profile.Helm module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'helm'"
        $c | Should -Match 'PowerShell.Profile.Helm'
    }
}
