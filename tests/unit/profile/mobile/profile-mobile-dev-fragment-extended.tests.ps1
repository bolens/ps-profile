# ===============================================
# profile-mobile-dev-fragment-extended.tests.ps1
# Execution tests for mobile-dev.ps1 fragment behavior
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

function script:Reset-MobileDevFragmentState {
    Clear-FragmentLoaded -FragmentName 'mobile-dev' -ErrorAction SilentlyContinue
}

Describe 'profile.d/mobile-dev.ps1 extended scenarios' {
    BeforeEach {
        Reset-MobileDevFragmentState
    }

    It 'Registers Android development helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'mobile-dev.ps1')

        Get-Command Connect-AndroidDevice -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Mirror-AndroidScreen -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'mobile-dev' | Should -Be $true
    }

    It 'Connect-AndroidDevice warns when adb is unavailable' {
        . (Join-Path $script:ProfileDir 'mobile-dev.ps1')

        Set-TestCommandAvailabilityState -CommandName 'adb' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('adb', [ref]$null)
        }

        $output = & { Connect-AndroidDevice } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'adb not found'
    }

    It 'Skips re-initialization when mobile-dev is already loaded' {
        . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
        $firstConnect = Get-Command Connect-AndroidDevice -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'mobile-dev.ps1')

        (Get-Command Connect-AndroidDevice -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstConnect.ScriptBlock.ToString()
    }
}
