# ===============================================
# profile-gem-fragment-extended.tests.ps1
# Execution tests for gem.ps1 fragment behavior
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

Describe 'profile.d/gem.ps1 extended scenarios' {
    It 'Registers gem helpers when gem is available' {
        Set-TestCommandAvailabilityState -CommandName 'gem' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'gem.ps1')

        Get-Command Install-GemPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-GemOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command gem-install -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips gem helper registration when gem is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'gem' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'gem.ps1')

        Get-Command Install-GemPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when gem is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'gem' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('gem', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'gem.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'gem not found'
    }
}
