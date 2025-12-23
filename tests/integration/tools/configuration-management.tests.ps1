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
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize configuration management tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Ansible helpers (ansible.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'ansible.ps1')
        }

        It 'Creates Invoke-Ansible function' {
            Get-Command Invoke-Ansible -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible alias for Invoke-Ansible' {
            Get-Alias ansible -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ansible).ResolvedCommandName | Should -Be 'Invoke-Ansible'
        }

        It 'Creates Invoke-AnsiblePlaybook function' {
            Get-Command Invoke-AnsiblePlaybook -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-playbook alias for Invoke-AnsiblePlaybook' {
            Get-Alias ansible-playbook -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ansible-playbook).ResolvedCommandName | Should -Be 'Invoke-AnsiblePlaybook'
        }

        It 'Creates Invoke-AnsibleGalaxy function' {
            Get-Command Invoke-AnsibleGalaxy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-galaxy alias for Invoke-AnsibleGalaxy' {
            Get-Alias ansible-galaxy -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ansible-galaxy).ResolvedCommandName | Should -Be 'Invoke-AnsibleGalaxy'
        }

        It 'Creates Invoke-AnsibleVault function' {
            Get-Command Invoke-AnsibleVault -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-vault alias for Invoke-AnsibleVault' {
            Get-Alias ansible-vault -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ansible-vault).ResolvedCommandName | Should -Be 'Invoke-AnsibleVault'
        }

        It 'Creates Get-AnsibleDoc function' {
            Get-Command Get-AnsibleDoc -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-doc alias for Get-AnsibleDoc' {
            Get-Alias ansible-doc -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ansible-doc).ResolvedCommandName | Should -Be 'Get-AnsibleDoc'
        }

        It 'Creates Get-AnsibleInventory function' {
            Get-Command Get-AnsibleInventory -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ansible-inventory alias for Get-AnsibleInventory' {
            Get-Alias ansible-inventory -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ansible-inventory).ResolvedCommandName | Should -Be 'Get-AnsibleInventory'
        }
    }
}

