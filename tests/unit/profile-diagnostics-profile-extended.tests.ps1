<#
tests/unit/profile-diagnostics-profile-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/diagnostics-modules/core/diagnostics-profile.ps1'
}
Describe 'profile.d/diagnostics-modules/core/diagnostics-profile.ps1 extended scenarios' {
    It 'Documents profile diagnostic helpers gated by PS_PROFILE_DEBUG' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Profile diagnostic functions'
        $c | Should -Match 'PS_PROFILE_DEBUG'
    }
    It 'Defines Show-ProfileDiagnostic and Show-ProfileStartupTime helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Show-ProfileDiagnostic'
        $c | Should -Match 'Show-ProfileStartupTime'
        $c | Should -Match 'PSProfileStartTime'
    }
    It 'Defines Test-ProfileHealth and Show-CommandUsageStats diagnostics' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-ProfileHealth'
        $c | Should -Match 'Show-CommandUsageStats'
        $c | Should -Match 'PSProfileDiagnosticsLoaded'
    }
}
