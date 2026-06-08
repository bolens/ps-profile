# ===============================================
# profile-procs-fragment-extended.tests.ps1
# Execution tests for procs.ps1 fragment behavior
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
    Mark-TestCommandsUnavailable -CommandNames @('procs')
    Set-TestCommandAvailabilityState -CommandName 'procs' -Available $true
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
    . (Join-Path $script:ProfileDir 'procs.ps1')
}

Describe 'profile.d/procs.ps1 extended scenarios' {
    It 'Registers ps alias targeting procs when procs is available' {
        Get-Alias ps -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias ps).Definition | Should -Be 'procs'
    }

    It 'Registers psgrep alias targeting procs' {
        Get-Alias psgrep -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias psgrep).Definition | Should -Be 'procs'
    }

    It 'Warns when procs is unavailable during fragment load' {
        Mark-TestCommandsUnavailable -CommandNames @('procs')
        Set-TestCommandAvailabilityState -CommandName 'procs' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('procs', [ref]$null)
        }

        $output = & {
            . (Join-Path $script:ProfileDir 'procs.ps1') 2>&1 3>&1
        } | Out-String

        Assert-TestMissingToolWarning -Output $output -Pattern 'procs not found'
    }
}
