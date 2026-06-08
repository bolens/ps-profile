<#
tests/unit/profile-api-tools-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/api-tools.ps1'
}
Describe 'profile.d/api-tools.ps1 extended scenarios' {
    It 'Declares standard tier for web and development API tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Defines Invoke-Bruno guarded by Test-CachedCommand availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Bruno'
        $c | Should -Match "Test-CachedCommand 'bruno'"
    }
    It 'Uses Test-FragmentLoaded guard and marks fragment loaded on success' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'api-tools'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'api-tools'"
    }
}
