<#
tests/unit/profile-main-loader-startup-summary-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 startup summary extended scenarios' {
    It 'Documents batch loading summary display section' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'DISPLAY BATCH LOADING SUMMARY'
        $c | Should -Match 'Show-BatchLoadingSummary'
    }
    It 'Documents missing tool warnings table section' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'DISPLAY MISSING TOOL WARNINGS'
        $c | Should -Match 'Show-MissingToolWarningsTable'
    }
    It 'Handles summary display errors when debug enabled' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Failed to display batch loading summary'
        $c | Should -Match 'Failed to display missing tool warnings table'
        $c | Should -Match 'PS_PROFILE_DEBUG'
    }
}
