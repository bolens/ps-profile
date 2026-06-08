<#
tests/unit/profile-rustup-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/rustup.ps1'
}
Describe 'profile.d/rustup.ps1 extended scenarios' {
    It 'Declares standard tier for Rustup toolchain helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Invoke-Rustup guarded by Test-CachedCommand rustup' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Rustup'
        $c | Should -Match 'Test-CachedCommand rustup'
    }
    It 'Registers rustup alias and documents PowerShell.Profile.Rustup module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'rustup'"
        $c | Should -Match 'PowerShell.Profile.Rustup'
    }
}
