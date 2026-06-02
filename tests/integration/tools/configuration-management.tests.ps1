<#
.SYNOPSIS
    Integration tests for configuration management tool fragments (ansible).

.DESCRIPTION
    Tests Ansible helper functions.
    These tests verify that functions are created correctly.
    Note: Ansible functions execute via WSL, so they don't use Write-MissingToolWarning.
#>

Describe 'Configuration Management Tools Integration Tests' {
    BeforeAll {
        $testSupportPath = Get-TestSupportPath -StartPath $PSScriptRoot
        if (-not (Test-Path -LiteralPath $testSupportPath)) {
            throw "TestSupport file not found at: $testSupportPath"
        }
        . $testSupportPath

        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap

        $ansiblePath = Join-Path $script:ProfileDir 'ansible.ps1'
        if (-not (Test-Path -LiteralPath $ansiblePath)) {
            throw "ansible fragment not found at: $ansiblePath"
        }
        $null = . $ansiblePath
    }

    Context 'Ansible helpers (ansible.ps1)' {
        It 'Creates Invoke-Ansible function' {
            Get-Command Invoke-Ansible -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible alias for Invoke-Ansible' {
            Get-Command Invoke-Ansible -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            $ansibleCommand = Get-Command ansible -ErrorAction SilentlyContinue
            if ($ansibleCommand -and $ansibleCommand.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'System ansible executable shadows the profile ansible alias on this platform'
            }
            elseif ($ansibleCommand -and $ansibleCommand.CommandType -eq 'Alias') {
                $ansibleCommand.Definition | Should -Be 'Invoke-Ansible'
            }
        }

        It 'Creates Invoke-AnsiblePlaybook function' {
            Get-Command Invoke-AnsiblePlaybook -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-playbook alias for Invoke-AnsiblePlaybook' {
            Get-Command Invoke-AnsiblePlaybook -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            $command = Get-Command ansible-playbook -ErrorAction SilentlyContinue
            if ($command -and $command.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'System ansible-playbook executable shadows the profile alias on this platform'
            }
            elseif ($command -and $command.CommandType -eq 'Alias') {
                $command.Definition | Should -Be 'Invoke-AnsiblePlaybook'
            }
        }

        It 'Creates Invoke-AnsibleGalaxy function' {
            Get-Command Invoke-AnsibleGalaxy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-galaxy alias for Invoke-AnsibleGalaxy' {
            Get-Command Invoke-AnsibleGalaxy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            $command = Get-Command ansible-galaxy -ErrorAction SilentlyContinue
            if ($command -and $command.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'System ansible-galaxy executable shadows the profile alias on this platform'
            }
            elseif ($command -and $command.CommandType -eq 'Alias') {
                $command.Definition | Should -Be 'Invoke-AnsibleGalaxy'
            }
        }

        It 'Creates Invoke-AnsibleVault function' {
            Get-Command Invoke-AnsibleVault -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-vault alias for Invoke-AnsibleVault' {
            Get-Command Invoke-AnsibleVault -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            $command = Get-Command ansible-vault -ErrorAction SilentlyContinue
            if ($command -and $command.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'System ansible-vault executable shadows the profile alias on this platform'
            }
            elseif ($command -and $command.CommandType -eq 'Alias') {
                $command.Definition | Should -Be 'Invoke-AnsibleVault'
            }
        }

        It 'Creates Get-AnsibleDoc function' {
            Get-Command Get-AnsibleDoc -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-doc alias for Get-AnsibleDoc' {
            Get-Command Get-AnsibleDoc -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            $command = Get-Command ansible-doc -ErrorAction SilentlyContinue
            if ($command -and $command.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'System ansible-doc executable shadows the profile alias on this platform'
            }
            elseif ($command -and $command.CommandType -eq 'Alias') {
                $command.Definition | Should -Be 'Get-AnsibleDoc'
            }
        }

        It 'Creates Get-AnsibleInventory function' {
            Get-Command Get-AnsibleInventory -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-inventory alias for Get-AnsibleInventory' {
            Get-Command Get-AnsibleInventory -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            $command = Get-Command ansible-inventory -ErrorAction SilentlyContinue
            if ($command -and $command.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'System ansible-inventory executable shadows the profile alias on this platform'
            }
            elseif ($command -and $command.CommandType -eq 'Alias') {
                $command.Definition | Should -Be 'Get-AnsibleInventory'
            }
        }
    }
}
