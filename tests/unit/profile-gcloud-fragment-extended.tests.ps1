<#
tests/unit/profile-gcloud-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/gcloud.ps1'
}
Describe 'profile.d/gcloud.ps1 extended scenarios' {
    It 'Declares standard tier for cloud and development GCP helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: cloud, development'
    }
    It 'Defines Invoke-GCloud guarded by Test-CachedCommand gcloud' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-GCloud'
        $c | Should -Match 'Test-CachedCommand gcloud'
    }
    It 'Registers gcloud alias and documents PowerShell.Profile.GCloud' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'gcloud'"
        $c | Should -Match 'PowerShell.Profile.GCloud'
    }
}
