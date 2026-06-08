<#
tests/unit/profile-lang-rust-audit-fragment-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-rust-audit.ps1'
}
Describe 'profile.d/lang-rust-audit.ps1 extended scenarios' {
    It 'Declares standard tier for Rust security and dependency auditing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Audit-RustProject'
        $c | Should -Match 'Test-RustOutdated'
    }
    It 'Wraps cargo-audit with Invoke-MissingToolWarning fallback' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'cargo-audit'
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Registers cargo-audit alias and marks lang-rust-audit fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'cargo-audit'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-rust-audit'"
    }
}
