# ===============================================
# profile-navi-fragment-extended.tests.ps1
# Execution tests for navi.ps1 fragment behavior
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

Describe 'profile.d/navi.ps1 extended scenarios' {
    It 'Registers navi helpers when navi is available' {
        Set-TestCommandAvailabilityState -CommandName 'navi' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'navi.ps1')

        Get-Command Invoke-NaviSearch -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-NaviBest -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command navis -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips navi helper registration when navi is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'navi' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'navi.ps1')

        Get-Command Invoke-NaviSearch -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when navi is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'navi' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('navi', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'navi.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'navi not found'
    }
}
