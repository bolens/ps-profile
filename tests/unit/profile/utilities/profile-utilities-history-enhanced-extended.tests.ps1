<#
tests/unit/profile-utilities-history-enhanced-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/history/utilities-history-enhanced.ps1'
}
Describe 'profile.d/utilities-modules/history/utilities-history-enhanced.ps1 extended scenarios' {
    It 'Documents enhanced history search and management utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Enhanced history utility functions'
        $c | Should -Match 'Advanced history search, navigation, and management'
    }
    It 'Defines Find-HistoryFuzzy and Find-HistoryQuick with Get-History' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Find-HistoryFuzzy'
        $c | Should -Match 'Find-HistoryQuick'
        $c | Should -Match 'Get-History'
        $c | Should -Match 'EnhancedHistoryLoaded'
    }
    It 'Registers fh alias and sets EnhancedHistoryLoaded global flag' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'fh'"
        $c | Should -Match "Set-Variable -Name 'EnhancedHistoryLoaded'"
        $c | Should -Match 'Show-HistoryStats'
    }
}
