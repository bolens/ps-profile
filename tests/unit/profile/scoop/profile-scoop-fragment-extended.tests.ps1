# ===============================================
# profile-scoop-fragment-extended.tests.ps1
# Execution tests for scoop.ps1 fragment behavior
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

Describe 'profile.d/scoop.ps1 extended scenarios' {
    It 'Registers Scoop helpers when scoop is available' {
        Set-TestCommandAvailabilityState -CommandName 'scoop' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'scoop.ps1')

        Get-Command Install-ScoopPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-ScoopPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command sinstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips Scoop helper registration when scoop is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'scoop' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'scoop.ps1')

        Get-Command Install-ScoopPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when scoop is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'scoop' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('scoop', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'scoop.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'Scoop not found'
    }
}
