# ===============================================
# profile-nimble-fragment-extended.tests.ps1
# Execution tests for nimble.ps1 fragment behavior
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

Describe 'profile.d/nimble.ps1 extended scenarios' {
    It 'Registers Nimble helpers when nimble is available' {
        Set-TestCommandAvailabilityState -CommandName 'nimble' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'nimble.ps1')

        Get-Command Test-NimbleOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Install-NimblePackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command nimble-outdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips Nimble helper registration when nimble is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'nimble' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'nimble.ps1')

        Get-Command Test-NimbleOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when nimble is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'nimble' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('nim', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'nimble.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'nim not found'
    }
}
