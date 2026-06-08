<#
tests/unit/profile-kubernetes-kube-logs-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/kubernetes-modules/kube-logs.ps1'
}
Describe 'profile.d/kubernetes-modules/kube-logs.ps1 extended scenarios' {
    It 'Declares standard tier for Kubernetes log tailing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Tail-KubeLogs using stern or kubectl'
    }
    It 'Defines Tail-KubeLogs with stern and kubectl fallbacks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tail-KubeLogs'
        $c | Should -Match "Test-CachedCommand 'stern'"
        $c | Should -Match "Test-CachedCommand 'kubectl'"
    }
    It 'Marks kube-logs fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'kube-logs'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'kube-logs'"
    }
}
