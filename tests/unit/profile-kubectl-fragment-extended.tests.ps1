<#
tests/unit/profile-kubectl-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/kubectl.ps1'
}
Describe 'profile.d/kubectl.ps1 extended scenarios' {
    It 'Declares essential tier for cloud containers and development environments' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Environment: cloud, containers, development'
    }
    It 'Defines Invoke-Kubectl guarded by Test-CachedCommand kubectl' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Kubectl'
        $c | Should -Match 'Test-CachedCommand kubectl'
    }
    It 'Registers k shorthand alias and documents PowerShell.Profile.Kubectl' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'k'"
        $c | Should -Match 'PowerShell.Profile.Kubectl'
    }
}
