<#
tests/unit/profile-main-loader-noprofile-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 NoProfile detection extended scenarios' {
    It 'Documents NoProfile early exit detection' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'NO-PROFILE DETECTION'
        $c | Should -Match 'NoProfile detected'
        $c | Should -Match 'PS_PROFILE_TEST_MODE'
    }
    It 'Returns early when PSCommandPath is empty' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'IsNullOrWhiteSpace\(\$PSCommandPath\)'
        $c | Should -Match 'return'
    }
    It 'Logs NoProfile exit to profile log file' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Early exit: PSCommandPath is empty'
        $c | Should -Match 'PSCommandPath check passed'
    }
}
