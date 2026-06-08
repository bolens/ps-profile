# ===============================================
# profile-ansible-fragment-extended.tests.ps1
# Execution tests for ansible.ps1 fragment behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/ansible.ps1 extended scenarios' {
    It 'Registers ansible helpers when Linux/macOS or WSL is available' {
        if (-not ($IsLinux -or $IsMacOS) -and -not (Test-CachedCommand 'wsl')) {
            Set-ItResult -Inconclusive -Because 'ansible fragment requires Linux, macOS, or WSL'
        }

        . (Join-Path $script:ProfileDir 'ansible.ps1')

        Get-Command Invoke-Ansible -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-AnsiblePlaybook -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ansible-playbook -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers ansible-galaxy alias for Invoke-AnsibleGalaxy' {
        if (-not ($IsLinux -or $IsMacOS) -and -not (Test-CachedCommand 'wsl')) {
            Set-ItResult -Inconclusive -Because 'ansible fragment requires Linux, macOS, or WSL'
        }

        . (Join-Path $script:ProfileDir 'ansible.ps1')

        Get-Command Invoke-AnsibleGalaxy -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ansible-galaxy -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Preserves existing ansible helper bodies on repeated fragment loads' {
        if (-not ($IsLinux -or $IsMacOS) -and -not (Test-CachedCommand 'wsl')) {
            Set-ItResult -Inconclusive -Because 'ansible fragment requires Linux, macOS, or WSL'
        }

        . (Join-Path $script:ProfileDir 'ansible.ps1')
        $firstPlaybook = Get-Command Invoke-AnsiblePlaybook -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'ansible.ps1')

        (Get-Command Invoke-AnsiblePlaybook -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstPlaybook.ScriptBlock.ToString()
    }
}
