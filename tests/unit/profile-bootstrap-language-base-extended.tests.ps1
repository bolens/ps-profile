<#
tests/unit/profile-bootstrap-language-base-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/LanguageBase.ps1'
}
Describe 'profile.d/bootstrap/LanguageBase.ps1 extended scenarios' {
    It 'Documents base module for language runtime CLI wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base module for language runtime wrappers'
        $c | Should -Match 'Go, Rust, Python, Node.js'
    }
    It 'Defines Register-LanguageModule for standardized language commands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-LanguageModule'
        $c | Should -Match 'version managers'
        $c | Should -Match 'virtualenvs, conda'
    }
    It 'Marks language-base fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'language-base'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'language-base'"
    }
}
