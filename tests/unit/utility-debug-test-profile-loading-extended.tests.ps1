<#
tests/unit/utility-debug-test-profile-loading-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/test-profile-loading.ps1.
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/test-profile-loading.ps1'
}
Describe 'test-profile-loading.ps1 extended scenarios' {
    It 'Enables PS_PROFILE_DEBUG level 3 during profile load test' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match "PS_PROFILE_DEBUG = '3'"
    }
    It 'Dot-sources the active user profile path' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\. \$PROFILE'
    }
    It 'Reports success when profile loading completes without exceptions' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Profile loading completed'
    }
    It 'Captures exception details when profile loading fails' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Profile loading failed'
        $c | Should -Match 'ScriptStackTrace'
    }
}
