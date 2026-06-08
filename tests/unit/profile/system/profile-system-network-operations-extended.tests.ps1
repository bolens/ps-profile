<#
tests/unit/profile-system-network-operations-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system/NetworkOperations.ps1'
}
Describe 'profile.d/system/NetworkOperations.ps1 extended scenarios' {
    It 'Documents network operation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Network operation utilities'
        $c | Should -Match 'netstat'
    }
    It 'Defines Get-NetworkPorts guarded by Test-CachedCommand netstat' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-NetworkPorts'
        $c | Should -Match "Test-CachedCommand 'netstat'"
        $c | Should -Match 'Invoke-WithWideEvent'
    }
    It 'Registers ports, ptest, dns, rest, and web aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ports'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ptest'"
        $c | Should -Match "Set-AgentModeAlias -Name 'dns'"
    }
}
