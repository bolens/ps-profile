
<#
.SYNOPSIS
    Integration tests for WSL, Ansible, and GitHub CLI fragments.

.DESCRIPTION
    Tests WSL helpers, Ansible wrappers, and GitHub CLI helper functions.
    These tests verify that functions are created correctly.
#>

Describe 'WSL, Ansible, and GitHub CLI Integration Tests' {
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
            Write-Error "Failed to initialize WSL/Ansible/GitHub CLI tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'WSL helpers (wsl.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'wsl.ps1')
        }

        It 'Creates Stop-WSL function' {
            Get-Command Stop-WSL -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates wsl-shutdown alias for Stop-WSL' {
            Get-Alias wsl-shutdown -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias wsl-shutdown).ResolvedCommandName | Should -Be 'Stop-WSL'
        }

        It 'Creates Get-WSLDistribution function' {
            Get-Command Get-WSLDistribution -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates wsl-list alias for Get-WSLDistribution' {
            Get-Alias wsl-list -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias wsl-list).ResolvedCommandName | Should -Be 'Get-WSLDistribution'
        }

        It 'Creates Start-UbuntuWSL function' {
            Get-Command Start-UbuntuWSL -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ubuntu alias for Start-UbuntuWSL' {
            Get-Alias ubuntu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ubuntu).ResolvedCommandName | Should -Be 'Start-UbuntuWSL'
        }
    }

    Context 'Ansible wrappers (ansible.ps1)' {
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

    Context 'GitHub CLI helpers (gh.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'gh.ps1')
        }

        It 'Creates Open-GitHubRepository function' {
            Get-Command Open-GitHubRepository -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gh-open alias for Open-GitHubRepository' {
            Get-Alias gh-open -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gh-open).ResolvedCommandName | Should -Be 'Open-GitHubRepository'
        }

        It 'Open-GitHubRepository function handles missing gh gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('gh', [ref]$null)
            }
            # Mock gh command availability as missing
            Mock-CommandAvailabilityPester -CommandName 'gh' -Available $false -Scope 'It'
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'gh' } -MockWith { $false }
            # Function should still exist even if gh is not available
            Get-Command Open-GitHubRepository -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            # Verify installation recommendation is provided
            $output = gh-open 2>&1 3>&1 | Out-String
            $output | Should -Match 'gh not found'
            $output | Should -Match 'scoop install gh'
        }

        It 'Creates Invoke-GitHubPullRequest function' {
            Get-Command Invoke-GitHubPullRequest -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gh-pr alias for Invoke-GitHubPullRequest' {
            Get-Alias gh-pr -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gh-pr).ResolvedCommandName | Should -Be 'Invoke-GitHubPullRequest'
        }

        It 'Invoke-GitHubPullRequest function handles missing gh gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('gh', [ref]$null)
            }
            # Mock gh command availability as missing
            Mock-CommandAvailabilityPester -CommandName 'gh' -Available $false -Scope 'It'
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'gh' } -MockWith { $false }
            # Function should still exist even if gh is not available
            Get-Command Invoke-GitHubPullRequest -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            # Verify installation recommendation is provided
            $output = gh-pr 2>&1 3>&1 | Out-String
            $output | Should -Match 'gh not found'
            $output | Should -Match 'scoop install gh'
        }
    }
}
