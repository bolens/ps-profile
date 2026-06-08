<#
tests/unit/profile-cloud-gcp-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/cloud-modules/cloud-gcp.ps1'
}
Describe 'profile.d/cloud-modules/cloud-gcp.ps1 extended scenarios' {
    It 'Declares standard tier for GCP cloud helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'GCP cloud helpers'
    }
    It 'Defines Set-GcpProject guarded by Test-CachedCommand gcloud' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-GcpProject'
        $c | Should -Match "Test-CachedCommand 'gcloud'"
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Marks cloud-gcp fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'cloud-gcp'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'cloud-gcp'"
    }
}
