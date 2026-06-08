# ===============================================
# profile-ssh-fragment-extended.tests.ps1
# Execution tests for ssh.ps1 fragment behavior
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

Describe 'profile.d/ssh.ps1 extended scenarios' {
    It 'Registers SSH helper functions and aliases when the fragment loads' {
        . (Join-Path $script:ProfileDir 'ssh.ps1')

        Get-Command Get-SSHKeys -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-SSHKeyIfNotLoaded -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Start-SSHAgent -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ssh-list -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ssh-add-if -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ssh-agent-start -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Add-SSHKeyIfNotLoaded warns and returns when no key path is provided' {
        . (Join-Path $script:ProfileDir 'ssh.ps1')

        $warnings = @()
        $previousWarningPreference = $WarningPreference
        try {
            $WarningPreference = 'Continue'
            Add-SSHKeyIfNotLoaded 3>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.WarningRecord]) {
                    $warnings += $_.Message
                }
            }
        }
        finally {
            $WarningPreference = $previousWarningPreference
        }

        $warnings -join ' ' | Should -Match 'Usage: Add-SSHKeyIfNotLoaded'
    }

    It 'Preserves existing SSH helper bodies on repeated fragment loads' {
        . (Join-Path $script:ProfileDir 'ssh.ps1')
        $firstKeys = Get-Command Get-SSHKeys -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'ssh.ps1')

        (Get-Command Get-SSHKeys -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstKeys.ScriptBlock.ToString()
    }
}
