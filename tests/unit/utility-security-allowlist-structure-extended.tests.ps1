<#
tests/unit/utility-security-allowlist-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/security/modules/SecurityAllowlist.psm1'
}
Describe 'scripts/utils/security/modules/SecurityAllowlist.psm1 structure extended scenarios' {
    It 'Documents security allowlist management utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Security allowlist management utilities'
        $c | Should -Match 'SecurityAllowlist.psm1'
    }
    It 'Defines default and file-based allowlists' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-DefaultAllowlist'
        $c | Should -Match 'Get-AllowlistFromFile'
        $c | Should -Match 'ExternalCommands'
    }
    It 'Defines allowlist test helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-AllowedCommand'
        $c | Should -Match 'Test-AllowedFile'
        $c | Should -Match 'Test-AllowedSecretPattern'
    }
}
