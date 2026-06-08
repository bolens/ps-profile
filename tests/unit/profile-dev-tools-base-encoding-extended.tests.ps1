<#
tests/unit/profile-dev-tools-base-encoding-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/encoding/base-encoding.ps1'
}
Describe 'profile.d/dev-tools-modules/encoding/base-encoding.ps1 extended scenarios' {
    It 'Documents Base32, Base58, and Base91 encoding utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base encoding utilities'
        $c | Should -Match 'Base32, Base58, and Base91'
    }
    It 'Defines Initialize-DevTools-BaseEncoding with Node.js script helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-BaseEncoding'
        $c | Should -Match 'ConvertTo-Base32'
        $c | Should -Match 'NodeJs.psm1'
    }
    It 'Registers base32-encode and base32-decode aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'base32-encode'"
        $c | Should -Match "Set-AgentModeAlias -Name 'base32-decode'"
    }
}
