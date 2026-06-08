<#
tests/unit/profile-main-loader-debug-setup-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 debug setup extended scenarios' {
    It 'Documents early debug mode setup' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'DEBUG MODE SETUP'
        $c | Should -Match 'Parse debug level immediately'
        $c | Should -Match 'PS_PROFILE_DEBUG'
    }
    It 'Configures VerbosePreference when debug level is set' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'VerbosePreference'
        $c | Should -Match 'debugLevel -ge 1'
        $c | Should -Match 'Debug level 3 detected'
    }
    It 'Logs debug check results to profile log file' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Debug mode check: PS_PROFILE_DEBUG'
        $c | Should -Match 'profileLogFile'
    }
}
