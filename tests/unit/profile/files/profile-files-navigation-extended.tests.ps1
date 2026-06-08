<#
tests/unit/profile-files-navigation-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-modules/navigation/files-navigation.ps1'
}
Describe 'profile.d/files-modules/navigation/files-navigation.ps1 extended scenarios' {
    It 'Documents lazy file navigation shortcuts for common directories' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'File navigation utility functions'
        $c | Should -Match 'Directory navigation shortcuts'
    }
    It 'Defines Ensure-FileNavigation with parent directory helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-FileNavigation'
        $c | Should -Match '__FileNavigation_UpOne'
        $c | Should -Match 'Get-UserHome'
        $c | Should -Match 'Get-UserDirectory'
    }
    It 'Registers desktop, downloads, and docs navigation aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-LocationDesktop'
        $c | Should -Match "Set-AgentModeAlias -Name 'desktop'"
        $c | Should -Match "Set-AgentModeAlias -Name 'downloads'"
        $c | Should -Match "Set-AgentModeAlias -Name 'docs'"
    }
}
