# ===============================================
# profile-profile-updates-fragment-extended.tests.ps1
# Execution tests for profile-updates.ps1 fragment behavior
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

function script:Reset-ProfileUpdatesFragmentState {
    Remove-Variable -Name 'ProfileUpdatesLoaded' -Scope Global -Force -ErrorAction SilentlyContinue
    Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
}

Describe 'profile.d/profile-updates.ps1 extended scenarios' {
    BeforeEach {
        Reset-ProfileUpdatesFragmentState
        $env:PS_PROFILE_TEST_MODE = '1'
    }

    AfterAll {
        Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
    }

    It 'Registers Test-ProfileUpdates and sets ProfileUpdatesLoaded' {
        . (Join-Path $script:ProfileDir 'profile-updates.ps1')

        Get-Command Test-ProfileUpdates -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:ProfileUpdatesLoaded | Should -Be $true
    }

    It 'Test-ProfileUpdates runs without error when forced' {
        . (Join-Path $script:ProfileDir 'profile-updates.ps1')

        { Test-ProfileUpdates -Force -MaxChanges 1 } | Should -Not -Throw
    }

    It 'Preserves existing update checker bodies on repeated fragment loads' {
        . (Join-Path $script:ProfileDir 'profile-updates.ps1')
        $firstUpdates = Get-Command Test-ProfileUpdates -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'profile-updates.ps1')

        (Get-Command Test-ProfileUpdates -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstUpdates.ScriptBlock.ToString()
    }
}
