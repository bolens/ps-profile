<#
tests/unit/profile-dev-tools-jwt-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/crypto/jwt.ps1'
}
Describe 'profile.d/dev-tools-modules/crypto/jwt.ps1 extended scenarios' {
    It 'Documents JWT encoding and decoding utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'JWT \(JSON Web Token\) utilities'
        $c | Should -Match 'Ensure-DevTools'
    }
    It 'Defines Initialize-DevTools-Jwt with Decode-Jwt and base64url helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-Jwt'
        $c | Should -Match 'Decode-Jwt'
        $c | Should -Match '_ConvertFrom-Base64Url'
    }
    It 'Registers jwt-decode and jwt-encode aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'jwt-decode'"
        $c | Should -Match "Set-AgentModeAlias -Name 'jwt-encode'"
        $c | Should -Match 'Encode-Jwt'
    }
}
