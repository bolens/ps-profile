<#
tests/unit/profile-lang-rust-tools-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-rust-tools.ps1'
}
Describe 'profile.d/lang-rust-tools.ps1 extended scenarios' {
    It 'Declares standard tier for cargo-binstall and cargo-watch helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Install-RustBinary'
        $c | Should -Match 'Watch-RustProject'
    }
    It 'Wraps cargo-binstall with Invoke-MissingToolWarning when unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'cargo-binstall'
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Registers cargo-binstall alias and marks lang-rust-tools fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'cargo-binstall'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-rust-tools'"
    }
}
