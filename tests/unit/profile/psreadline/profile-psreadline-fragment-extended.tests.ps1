# ===============================================
# profile-psreadline-fragment-extended.tests.ps1
# Execution tests for psreadline.ps1 fragment behavior
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

function script:Reset-PSReadLineFragmentState {
    Clear-FragmentLoaded -FragmentName 'psreadline' -ErrorAction SilentlyContinue
}

Describe 'profile.d/psreadline.ps1 extended scenarios' {
    BeforeEach {
        Reset-PSReadLineFragmentState
    }

    It 'Marks the psreadline fragment loaded after dot-sourcing' {
        . (Join-Path $script:ProfileDir 'psreadline.ps1')

        Test-FragmentLoaded -FragmentName 'psreadline' | Should -Be $true
    }

    It 'Imports PSReadLine when the module is list-available' {
        if (-not (Get-Module -ListAvailable -Name PSReadLine -ErrorAction SilentlyContinue)) {
            Set-ItResult -Inconclusive -Because 'PSReadLine module is not installed in this environment'
            return
        }

        . (Join-Path $script:ProfileDir 'psreadline.ps1')

        Get-Module -Name PSReadLine -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips re-initialization when psreadline is already loaded' {
        . (Join-Path $script:ProfileDir 'psreadline.ps1')
        Test-FragmentLoaded -FragmentName 'psreadline' | Should -Be $true

        . (Join-Path $script:ProfileDir 'psreadline.ps1')
        Test-FragmentLoaded -FragmentName 'psreadline' | Should -Be $true
    }
}
