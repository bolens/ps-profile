<#
tests/unit/profile-system-info-fragment-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system-info.ps1'
}
Describe 'profile.d/system-info.ps1 extended scenarios' {
    It 'Declares essential tier for system information helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Environment: server, development'
    }
    It 'Defines uptime and battery helpers with cross-platform branches' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-SystemUptime'
        $c | Should -Match 'Get-BatteryInfo'
        $c | Should -Match '/proc/uptime'
    }
    It 'Registers uptime and battery aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'uptime'"
        $c | Should -Match "Set-AgentModeAlias -Name 'battery'"
    }
}
