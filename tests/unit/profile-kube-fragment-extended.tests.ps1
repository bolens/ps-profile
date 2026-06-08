<#
tests/unit/profile-kube-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/kube.ps1'
}
Describe 'profile.d/kube.ps1 extended scenarios' {
    It 'Declares essential tier for Minikube cluster helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Minikube helper'
    }
    It 'Defines Start-MinikubeCluster guarded by Test-CachedCommand minikube' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-MinikubeCluster'
        $c | Should -Match 'Test-CachedCommand minikube'
    }
    It 'Notes kubectl shorthands live in kubectl.ps1 and registers minikube-start alias' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'kubectl.ps1'
        $c | Should -Match "Set-AgentModeAlias -Name 'minikube-start'"
    }
}
