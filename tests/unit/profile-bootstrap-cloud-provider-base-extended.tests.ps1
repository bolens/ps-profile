<#
tests/unit/profile-bootstrap-cloud-provider-base-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/CloudProviderBase.ps1'
}
Describe 'profile.d/bootstrap/CloudProviderBase.ps1 extended scenarios' {
    It 'Documents base module for cloud provider CLI wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'cloud provider'
        $c | Should -Match 'Invoke-CloudCommand'
    }
    It 'Defines Set-CloudProfile and Get-CloudResources helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-CloudProfile'
        $c | Should -Match 'Get-CloudResources'
        $c | Should -Match 'Test-CloudConnection'
    }
    It 'Defines Invoke-CloudMissingToolWarning and marks cloud-provider-base loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-CloudMissingToolWarning'
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'cloud-provider-base'"
    }
}
