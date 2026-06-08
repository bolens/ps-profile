<#
tests/unit/profile-lang-go-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-go.ps1'
}
Describe 'profile.d/lang-go.ps1 extended scenarios' {
    It 'Declares standard tier depending on lang-go-basic fragment' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env, lang-go-basic'
    }
    It 'Dot-sources lang-go-tools.ps1 compatibility loader' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'lang-go-tools\.ps1'
        $c | Should -Match 'golangci-lint'
    }
    It 'Marks lang-go fragment loaded after tools module import' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'lang-go'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-go'"
    }
}
