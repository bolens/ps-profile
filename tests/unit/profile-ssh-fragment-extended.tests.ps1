<#
tests/unit/profile-ssh-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/ssh.ps1'
}
Describe 'profile.d/ssh.ps1 extended scenarios' {
    It 'Declares essential tier for server and development SSH helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Environment: server, development'
    }
    It 'Defines SSH key and agent helpers with idempotent guards' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-SSHKeys'
        $c | Should -Match 'Add-SSHKeyIfNotLoaded'
        $c | Should -Match 'Start-SSHAgent'
    }
    It 'Registers ssh-list, ssh-add-if, and ssh-agent-start aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ssh-list'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ssh-add-if'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ssh-agent-start'"
    }
}
