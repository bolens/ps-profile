<#
tests/unit/profile-utilities-network-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/network/utilities-network.ps1'
}
Describe 'profile.d/utilities-modules/network/utilities-network.ps1 extended scenarios' {
    It 'Documents network utilities for weather, IP, and speed tests' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Network utility functions'
        $c | Should -Match 'Weather, IP address, speed test'
    }
    It 'Defines Get-Weather, Get-MyIP, and Start-SpeedTest helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-Weather'
        $c | Should -Match 'Get-MyIP'
        $c | Should -Match 'Start-SpeedTest'
        $c | Should -Match 'wttr.in'
    }
    It 'Registers weather, myip, and speedtest aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'weather'"
        $c | Should -Match "Set-AgentModeAlias -Name 'myip'"
        $c | Should -Match "Set-AgentModeAlias -Name 'speedtest'"
    }
}
