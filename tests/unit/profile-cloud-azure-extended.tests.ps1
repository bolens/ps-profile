<#
tests/unit/profile-cloud-azure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/cloud-modules/cloud-azure.ps1'
}
Describe 'profile.d/cloud-modules/cloud-azure.ps1 extended scenarios' {
    It 'Declares standard tier for Azure cloud helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Azure cloud helpers'
    }
    It 'Defines Set-AzureSubscription guarded by Test-CachedCommand az' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-AzureSubscription'
        $c | Should -Match "Test-CachedCommand 'az'"
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Marks cloud-azure fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'cloud-azure'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'cloud-azure'"
    }
}
