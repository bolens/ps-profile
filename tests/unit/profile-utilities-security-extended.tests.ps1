<#
tests/unit/profile-utilities-security-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/system/utilities-security.ps1'
}
Describe 'profile.d/utilities-modules/system/utilities-security.ps1 extended scenarios' {
    It 'Documents security utilities for path validation and passwords' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Security utility functions'
        $c | Should -Match 'Path validation and password generation'
    }
    It 'Defines Test-SafePath to prevent path traversal attacks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-SafePath'
        $c | Should -Match 'path traversal attacks'
        $c | Should -Match 'Resolve-Path'
    }
    It 'Defines New-RandomPassword and registers pwgen alias' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-RandomPassword'
        $c | Should -Match "Set-AgentModeAlias -Name 'pwgen'"
    }
}
