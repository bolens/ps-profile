<#
tests/unit/profile-system-systeminfo-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system/SystemInfo.ps1'
}
Describe 'profile.d/system/SystemInfo.ps1 extended scenarios' {
    It 'Documents system information utilities with Unix equivalents' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'System information utilities'
        $c | Should -Match "Unix 'which' equivalent"
    }
    It 'Defines Get-CommandInfo, Get-DiskUsage, and Get-TopProcesses' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-CommandInfo'
        $c | Should -Match 'Get-DiskUsage'
        $c | Should -Match 'Get-TopProcesses'
        $c | Should -Match 'Get-PSDrive'
    }
    It 'Registers which, df, and htop aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'which'"
        $c | Should -Match "Set-AgentModeAlias -Name 'df'"
        $c | Should -Match "Set-AgentModeAlias -Name 'htop'"
    }
}
