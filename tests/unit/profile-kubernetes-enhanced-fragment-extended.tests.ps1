<#
tests/unit/profile-kubernetes-enhanced-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/kubernetes-enhanced.ps1'
}
Describe 'profile.d/kubernetes-enhanced.ps1 extended scenarios' {
    It 'Declares standard tier and loads kubernetes-modules subdirectory' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'kubernetes-modules'
    }
    It 'Registers context logs workloads and console kube helper modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'kube-context\.ps1'
        $c | Should -Match 'kube-logs\.ps1'
        $c | Should -Match 'kube-workloads\.ps1'
        $c | Should -Match 'kube-console\.ps1'
    }
    It 'Uses Test-FragmentLoaded guard before modular import' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'kubernetes-enhanced'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'kubernetes-enhanced'"
    }
}
