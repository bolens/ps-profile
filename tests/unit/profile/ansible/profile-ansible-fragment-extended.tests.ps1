<#
tests/unit/profile-ansible-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/ansible.ps1'
}
Describe 'profile.d/ansible.ps1 extended scenarios' {
    It 'Declares essential tier with Linux native and WSL Windows invocation' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'via WSL on Windows'
    }
    It 'Defines Invoke-AnsiblePlaybook and Invoke-AnsibleGalaxy helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-AnsiblePlaybook'
        $c | Should -Match 'Invoke-AnsibleGalaxy'
    }
    It 'Registers ansible-playbook alias via Set-AgentModeAlias' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ansible-playbook'"
        $c | Should -Match 'PowerShell.Profile.Ansible'
    }
}
