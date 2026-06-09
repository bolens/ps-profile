# ===============================================
# profile-beads-fragment-extended.tests.ps1
# Execution tests for beads.ps1 fragment behavior
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-BeadsFragmentState {
    Clear-FragmentLoaded -FragmentName 'beads' -ErrorAction SilentlyContinue
}

Describe 'profile.d/beads.ps1 extended scenarios' {
    BeforeEach {
        Reset-BeadsFragmentState
    }

    It 'Registers Beads helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'beads.ps1')

        Get-Command Invoke-Beads -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command bd -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'beads' | Should -Be $true
    }

    It 'Invoke-Beads warns when bd is unavailable' {
        . (Join-Path $script:ProfileDir 'beads.ps1')

        Set-TestCommandAvailabilityState -CommandName 'bd' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('bd', [ref]$null)
        }

        $output = Invoke-Beads --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'bd not found'
    }

    It 'Skips re-initialization when beads fragment is already loaded' {
        . (Join-Path $script:ProfileDir 'beads.ps1')
        $firstBeads = Get-Command Invoke-Beads -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'beads.ps1')

        (Get-Command Invoke-Beads -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstBeads.ScriptBlock.ToString()
    }
}
