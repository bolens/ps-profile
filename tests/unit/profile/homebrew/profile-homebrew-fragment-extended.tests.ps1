# ===============================================
# profile-homebrew-fragment-extended.tests.ps1
# Execution tests for homebrew.ps1 fragment behavior
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

Describe 'profile.d/homebrew.ps1 extended scenarios' {
    It 'Registers Homebrew helpers when brew is available' {
        Set-TestCommandAvailabilityState -CommandName 'brew' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'homebrew.ps1')

        Get-Command Install-BrewPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-BrewOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command brewinstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips Homebrew helper registration when brew is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'brew' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'homebrew.ps1')

        Get-Command Install-BrewPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when brew is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'brew' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('homebrew', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'homebrew.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'brew not found'
    }
}
