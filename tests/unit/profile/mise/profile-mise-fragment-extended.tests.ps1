# ===============================================
# profile-mise-fragment-extended.tests.ps1
# Execution tests for mise.ps1 fragment behavior
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

Describe 'profile.d/mise.ps1 extended scenarios' {
    It 'Registers mise helpers when mise is available' {
        Set-TestCommandAvailabilityState -CommandName 'mise' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'mise.ps1')

        Get-Command Test-MiseOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Update-MiseRuntimes -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command mise-outdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips mise helper registration when mise is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'mise' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'mise.ps1')

        Get-Command Test-MiseOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when mise is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'mise' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('mise', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'mise.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mise not found'
    }
}
