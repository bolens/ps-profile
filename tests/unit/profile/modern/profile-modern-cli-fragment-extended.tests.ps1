# ===============================================
# profile-modern-cli-fragment-extended.tests.ps1
# Execution tests for modern-cli.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'modern-cli.ps1')
}

Describe 'profile.d/modern-cli.ps1 extended scenarios' {
    It 'Loads enhanced CLI wrapper functions from cli-modules' {
        Get-Command Find-WithFd -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Grep-WithRipgrep -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command View-WithBat -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Navigate-WithZoxide -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers guarded tool wrapper functions for common modern CLI tools' {
        Get-Command bat -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command fd -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command zoxide -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Find-WithFd warns when fd is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('fd')
        Set-TestCommandAvailabilityState -CommandName 'fd' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('fd', [ref]$null)
        }

        $output = Find-WithFd -Pattern 'modern-cli-probe' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'fd not found'
    }
}
