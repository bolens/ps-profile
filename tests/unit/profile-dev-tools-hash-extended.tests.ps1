<#
tests/unit/profile-dev-tools-hash-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/crypto/hash.ps1'
}
Describe 'profile.d/dev-tools-modules/crypto/hash.ps1 extended scenarios' {
    It 'Documents hash generator utilities for text input' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Hash generator utilities'
        $c | Should -Match 'Ensure-DevTools'
    }
    It 'Defines Initialize-DevTools-Hash with SHA256 default algorithm' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-Hash'
        $c | Should -Match 'Get-TextHash'
        $c | Should -Match 'SHA256'
    }
    It 'Registers text-hash alias targeting Get-TextHash' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'text-hash'"
        $c | Should -Match "Target 'Get-TextHash'"
    }
}
