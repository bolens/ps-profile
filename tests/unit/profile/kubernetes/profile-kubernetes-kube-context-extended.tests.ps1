<#
tests/unit/profile-kubernetes-kube-context-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/kubernetes-modules/kube-context.ps1'
}
Describe 'profile.d/kubernetes-modules/kube-context.ps1 extended scenarios' {
    It 'Declares standard tier for context and namespace helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'kubectx/kubens fallbacks'
    }
    It 'Defines Set-KubeContext and Set-KubeNamespace with tool detection' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-KubeContext'
        $c | Should -Match 'Set-KubeNamespace'
        $c | Should -Match "Test-CachedCommand 'kubectx'"
        $c | Should -Match "Test-CachedCommand 'kubens'"
    }
    It 'Marks kube-context fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'kube-context'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'kube-context'"
    }
}
