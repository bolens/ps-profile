<#
tests/unit/profile-lang-rust-build-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-rust-build.ps1'
}
Describe 'profile.d/lang-rust-build.ps1 extended scenarios' {
    It 'Declares standard tier for Rust build and cache helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Build-RustRelease'
    }
    It 'Defines Build-RustRelease wrapping cargo build --release' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Build-RustRelease'
        $c | Should -Match 'cargo build --release'
    }
    It 'Registers cargo-build-release alias and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'cargo-build-release'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-rust-build'"
    }
}
