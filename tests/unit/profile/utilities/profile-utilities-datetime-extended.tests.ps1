<#
tests/unit/profile-utilities-datetime-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/data/utilities-datetime.ps1'
}
Describe 'profile.d/utilities-modules/data/utilities-datetime.ps1 extended scenarios' {
    It 'Documents DateTime utilities for epoch conversion and formatting' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DateTime utility functions'
        $c | Should -Match 'Epoch conversion and date/time formatting'
    }
    It 'Defines ConvertFrom-Epoch, ConvertTo-Epoch, and Get-Epoch helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConvertFrom-Epoch'
        $c | Should -Match 'ConvertTo-Epoch'
        $c | Should -Match 'Get-Epoch'
        $c | Should -Match 'FromUnixTimeSeconds'
    }
    It 'Registers from-epoch, to-epoch, epoch, and now aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'from-epoch'"
        $c | Should -Match "Set-AgentModeAlias -Name 'to-epoch'"
        $c | Should -Match "Set-AgentModeAlias -Name 'now'"
    }
}
