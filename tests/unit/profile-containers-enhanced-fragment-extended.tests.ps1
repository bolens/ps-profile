<#
tests/unit/profile-containers-enhanced-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/containers-enhanced.ps1'
}
Describe 'profile.d/containers-enhanced.ps1 extended scenarios' {
    It 'Declares standard tier depending on containers fragment' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env, containers'
    }
    It 'Defines Start-PodmanDesktop and Deploy-Balena container helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-PodmanDesktop'
        $c | Should -Match 'Deploy-Balena'
    }
    It 'Registers functions with Set-AgentModeFunction and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-AgentModeFunction'
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'containers-enhanced'"
    }
}
