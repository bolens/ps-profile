<#
tests/unit/profile-main-loader-psreadline-deferred-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 deferred PSReadLine loading extended scenarios' {
    It 'Documents lazy PSReadLine loading via profile fragment' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'PSReadLine is loaded lazily'
        $c | Should -Match 'profile.d/psreadline.ps1'
        $c | Should -Match 'startup performance'
    }
    It 'References Enable-PSReadLine entry point' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Enable-PSReadLine'
        $c | Should -Match 'enhanced configuration'
    }
    It 'Keeps main profile minimal before fragment load' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'intentionally small'
        $c | Should -Match 'feature-rich helpers live in'
    }
}
