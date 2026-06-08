<#
tests/unit/profile-utilities-history-base-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/history/utilities-history.ps1'
}
Describe 'profile.d/utilities-modules/history/utilities-history.ps1 extended scenarios' {
    It 'Documents basic command history viewing and searching' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Command history utility functions'
        $c | Should -Match 'History viewing and searching'
    }
    It 'Defines Get-History wrapper showing last 20 commands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Get-History'
        $c | Should -Match 'Microsoft.PowerShell.Core\\Get-History'
        $c | Should -Match 'Select-Object -Last 20'
    }
    It 'Defines Find-History and registers hg alias' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Find-History'
        $c | Should -Match 'Select-String'
        $c | Should -Match "Set-AgentModeAlias -Name 'hg'"
    }
}
