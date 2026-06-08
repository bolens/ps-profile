<#
tests/unit/profile-kubernetes-kube-console-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/kubernetes-modules/kube-console.ps1'
}
Describe 'profile.d/kubernetes-modules/kube-console.ps1 extended scenarios' {
    It 'Declares standard tier for Kubernetes console tools' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Start-Minikube and Start-K9s helpers'
    }
    It 'Defines Start-Minikube and Start-K9s guarded by Test-CachedCommand' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-Minikube'
        $c | Should -Match 'Start-K9s'
        $c | Should -Match "Test-CachedCommand 'minikube'"
        $c | Should -Match "Test-CachedCommand 'k9s'"
    }
    It 'Marks kube-console fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'kube-console'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'kube-console'"
    }
}
