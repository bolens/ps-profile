<#
tests/unit/profile-git-basic-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git-modules/core/git-basic.ps1'
}
Describe 'profile.d/git-modules/core/git-basic.ps1 extended scenarios' {
    It 'Documents basic Git command wrappers for status through fetch' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Basic Git command functions'
        $c | Should -Match 'Status, add, commit, push, pull, log, diff, branch, checkout'
    }
    It 'Registers core Git helpers via Set-AgentModeFunction and Invoke-GitCommand' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-AgentModeFunction -Name ''Invoke-GitStatus'''
        $c | Should -Match 'Invoke-GitCommand -Subcommand ''status'''
        $c | Should -Match 'Invoke-GitCommand -Subcommand ''commit'''
    }
    It 'Registers gs, ga, gc, gp, and gl Git aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'gs'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ga'"
        $c | Should -Match "Set-AgentModeAlias -Name 'gc'"
        $c | Should -Match "Set-AgentModeAlias -Name 'gp'"
    }
}
