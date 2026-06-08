<#
tests/unit/profile-main-loader-startup-logging-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 startup logging extended scenarios' {
    It 'Documents profile startup logging section' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'PROFILE STARTUP LOGGING'
        $c | Should -Match 'Profile startup detected'
        $c | Should -Match 'PSCommandPath'
    }
    It 'Logs startup when debug is enabled' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'PS_PROFILE_DEBUG'
        $c | Should -Match 'Write-Host .+msg -ForegroundColor Cyan'
        $c | Should -Match 'powershell-profile-load.log'
    }
    It 'Handles startup logging errors gracefully' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Error in startup logging'
        $c | Should -Match 'ErrorAction SilentlyContinue'
    }
}
