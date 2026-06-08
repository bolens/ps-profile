# ===============================================
# profile-oh-my-posh-fragment-extended.tests.ps1
# Execution tests for oh-my-posh.ps1 fragment behavior
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
    Mark-TestCommandsUnavailable -CommandNames @('oh-my-posh', 'starship')
    Set-TestCommandAvailabilityState -CommandName 'oh-my-posh' -Available $false
    Set-TestCommandAvailabilityState -CommandName 'starship' -Available $false
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
    . (Join-Path $script:ProfileDir 'oh-my-posh.ps1')
}

function script:Reset-OhMyPoshFragmentState {
    Remove-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue
}

Describe 'profile.d/oh-my-posh.ps1 extended scenarios' {
    BeforeEach {
        Reset-OhMyPoshFragmentState
    }

    It 'Registers Initialize-OhMyPosh lazy initializer' {
        Get-Command Initialize-OhMyPosh -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Initialize-OhMyPosh returns without error when oh-my-posh is unavailable' {
        { Initialize-OhMyPosh } | Should -Not -Throw
        Get-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
    }

    It 'Initialize-OhMyPosh is idempotent once OhMyPoshInitialized is set' {
        Set-Variable -Name 'OhMyPoshInitialized' -Scope Global -Value $true -Force
        { Initialize-OhMyPosh } | Should -Not -Throw
    }
}
