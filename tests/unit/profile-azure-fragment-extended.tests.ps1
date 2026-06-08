<#
tests/unit/profile-azure-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/azure.ps1'
}
Describe 'profile.d/azure.ps1 extended scenarios' {
    It 'Declares standard tier for cloud and development Azure helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: cloud, development'
    }
    It 'Defines Invoke-Azure and Invoke-AzureDeveloper CLI wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Azure'
        $c | Should -Match 'function Invoke-AzureDeveloper'
    }
    It 'Uses Test-CachedCommand for az and azd availability checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-CachedCommand'
        $c | Should -Match 'PowerShell.Profile.Azure'
    }
}
