<#
tests/unit/profile-shortcuts-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/shortcuts.ps1'
}
Describe 'profile.d/shortcuts.ps1 extended scenarios' {
    It 'Declares essential tier for editor and navigation shortcuts' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Get-AvailableEditor using Test-CachedCommand preference list' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-AvailableEditor'
        $c | Should -Match 'Test-CachedCommand'
        $c | Should -Match 'Open-VSCode'
    }
    It 'Registers vsc, e, and project-root aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'vsc'"
        $c | Should -Match "Set-AgentModeAlias -Name 'e'"
        $c | Should -Match "Set-AgentModeAlias -Name 'project-root'"
    }
}
