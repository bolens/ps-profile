<#
tests/unit/profile-kubernetes-kube-workloads-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/kubernetes-modules/kube-workloads.ps1'
}
Describe 'profile.d/kubernetes-modules/kube-workloads.ps1 extended scenarios' {
    It 'Declares standard tier for Kubernetes workload operations' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Kubernetes workload operations'
    }
    It 'Defines Get-KubeResources, Exec-KubePod, and Apply-KubeManifests helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-KubeResources'
        $c | Should -Match 'Exec-KubePod'
        $c | Should -Match 'Apply-KubeManifests'
        $c | Should -Match 'PortForward-KubeService'
    }
    It 'Marks kube-workloads fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'kube-workloads'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'kube-workloads'"
    }
}
