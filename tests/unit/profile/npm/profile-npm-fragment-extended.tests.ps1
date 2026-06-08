# ===============================================
# profile-npm-fragment-extended.tests.ps1
# Execution tests for npm.ps1 fragment behavior
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

Describe 'profile.d/npm.ps1 extended scenarios' {
    It 'Registers npm package helpers when npm is available' {
        Set-TestCommandAvailabilityState -CommandName 'npm' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'npm.ps1')

        Get-Command Install-NpmPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Remove-NpmPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command npminstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips npm helper registration when npm is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'npm' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'npm.ps1')

        Get-Command Install-NpmPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Install-NpmPackage warns when npm becomes unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'npm' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'npm.ps1')

        Set-TestCommandAvailabilityState -CommandName 'npm' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('npm', [ref]$null)
        }

        $output = Install-NpmPackage 'express' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'npm not found'
    }
}
