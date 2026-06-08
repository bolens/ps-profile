# ===============================================
# profile-gradle-fragment-extended.tests.ps1
# Execution tests for gradle.ps1 fragment behavior
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

Describe 'profile.d/gradle.ps1 extended scenarios' {
    It 'Registers gradle helpers when gradle is available' {
        Set-TestCommandAvailabilityState -CommandName 'gradle' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'gradle.ps1')

        Get-Command Test-GradleOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Update-GradleWrapper -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command gradle-outdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips gradle helper registration when gradle is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'gradle' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'gradle.ps1')

        Get-Command Test-GradleOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when gradle is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'gradle' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('gradle', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'gradle.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'gradle not found'
    }
}
