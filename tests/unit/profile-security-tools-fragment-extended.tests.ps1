<#
tests/unit/profile-security-tools-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/security-tools.ps1'
}
Describe 'profile.d/security-tools.ps1 extended scenarios' {
    It 'Declares standard tier for security scanning helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'gitleaks'
        $c | Should -Match 'trufflehog'
    }
    It 'Uses Invoke-MissingToolWarning when gitleaks is unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-CachedCommand 'gitleaks'"
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Marks security-tools fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'security-tools'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'security-tools'"
    }
}
