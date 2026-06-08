# ===============================================
# profile-pnpm-fragment-extended.tests.ps1
# Execution tests for pnpm.ps1 fragment behavior
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

Describe 'profile.d/pnpm.ps1 extended scenarios' {
    It 'Registers pnpm helpers and aliases when pnpm is available' {
        Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pnpm.ps1')

        Get-Command Invoke-PnpmRun -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command pnrun -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias npm -ErrorAction Stop).Definition | Should -Be 'pnpm'
    }

    It 'Skips pnpm helper registration when pnpm is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pnpm.ps1')

        Get-Command Invoke-PnpmRun -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Test-PnpmOutdated warns when pnpm becomes unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pnpm.ps1')

        Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('pnpm', [ref]$null)
        }

        $output = Test-PnpmOutdated 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pnpm not found'
    }
}
